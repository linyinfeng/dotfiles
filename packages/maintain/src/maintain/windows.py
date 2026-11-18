"""Build a private, unattended Windows Pro disk for a one-time Incus import."""

import hashlib
import html
import io
import json
import os
import platform
import re
import secrets
import shutil
import socket
import subprocess
import tarfile
import tempfile
import time
import urllib.parse
import urllib.request
import uuid
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Annotated, Literal

import typer

from maintain.common import dotfiles_dir, message, run

app = typer.Typer(help="unattended Windows installation images")
ASSETS = Path(__file__).with_name("windows_assets")
LANGUAGES = {"zh-CN": "Chinese (Simplified)", "en-US": "English"}
READY = b"MAINTAIN_WINDOWS_IMAGE_READY"
USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0"


def microsoft_url(url: str) -> str:
    parsed = urllib.parse.urlsplit(url)
    host = parsed.hostname or ""
    if (
        parsed.scheme != "https"
        or not (host == "microsoft.com" or host.endswith(".microsoft.com"))
        or parsed.username
        or parsed.password
    ):
        raise typer.BadParameter("Windows ISO URL must use HTTPS on microsoft.com")
    return url


def request(url: str, *, referer: str | None = None) -> bytes:
    headers = {"User-Agent": USER_AGENT}
    if referer:
        headers["Referer"] = referer
    with urllib.request.urlopen(
        urllib.request.Request(url, headers=headers), timeout=60
    ) as response:
        return response.read(2 * 1024 * 1024)


def windows_url(locale: str) -> str:
    """Resolve Microsoft's current consumer ISO using its software-download API.

    Same public download flow used by Quickget/Fido. Microsoft may require a
    browser on some networks; --iso and --iso-url keep that from blocking builds.
    """
    page = "https://www.microsoft.com/en-us/software-download/windows11"
    try:
        page_html = request(page).decode()
        product = re.search(r'<option\s+value="(\d+)">\s*Windows', page_html)
        if not product:
            raise ValueError("download page has no Windows product ID")
        session = str(uuid.uuid4())
        request(
            f"https://vlscppe.microsoft.com/tags?org_id=y6jn8c31&session_id={session}"
        )
        base = "https://www.microsoft.com/software-download-connector/api/"
        common = {"profile": "606624d44113", "Locale": "en-US", "sessionID": session}
        query = urllib.parse.urlencode(common | {"ProductEditionId": product[1]})
        skus = json.loads(request(base + "getskuinformationbyproductedition?" + query))
        sku = next(
            item["Id"]
            for item in skus["Skus"]
            if LANGUAGES[locale]
            in (item.get("Language"), item.get("LocalizedLanguage"))
        )
        query = urllib.parse.urlencode(common | {"SKU": sku})
        links = json.loads(
            request(base + "GetProductDownloadLinksBySku?" + query, referer=page)
        )
        return microsoft_url(
            next(
                item["Uri"]
                for item in links["ProductDownloadOptions"]
                if "x64" in item["Uri"].lower()
            )
        )
    except (OSError, ValueError, KeyError, StopIteration) as error:
        raise typer.BadParameter(
            "Microsoft's automatic ISO download is unavailable. Open "
            f"{page} and pass --iso /path/to/Win11.iso or --iso-url <official-link>."
        ) from error


def sha256(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def obtain_iso(cache: Path, locale: str, url: str | None, expected: str | None) -> Path:
    suffix = ""
    if url:
        microsoft_url(url)
        suffix = (
            "-"
            + hashlib.sha256(urllib.parse.urlsplit(url).path.encode()).hexdigest()[:12]
        )
    target = cache / f"windows-11-{locale}{suffix}.iso"
    if target.is_symlink():
        raise typer.BadParameter(f"cache must not be a symlink: {target}")
    if not target.exists():
        source = microsoft_url(url) if url else windows_url(locale)
        partial = target.with_suffix(".iso.part")
        if partial.is_symlink():
            raise typer.BadParameter(f"cache must not be a symlink: {partial}")
        message("downloading Windows from Microsoft (partial downloads are resumable)")
        run(
            [
                "curl",
                "--fail",
                "--location",
                "--retry",
                "3",
                "--continue-at",
                "-",
                "--proto",
                "=https",
                "--proto-redir",
                "=https",
                "--output",
                str(partial),
                source,
            ],
            umask=0o077,
        )
        partial.rename(target)
    verify_iso(target, expected)
    return target


def verify_iso(path: Path, expected: str | None) -> None:
    if not path.is_file():
        raise typer.BadParameter(f"ISO does not exist: {path}")
    # Reject HTML error pages even when a download endpoint returns HTTP 200.
    with path.open("rb") as stream:
        stream.seek(0x8001)
        if stream.read(5) != b"CD001":
            raise typer.BadParameter(
                f"not an ISO9660 Windows installation image: {path}"
            )
    if expected and sha256(path) != expected.lower():
        raise typer.BadParameter(f"Windows ISO SHA-256 mismatch: {path}")


def discover_iso(
    iso: Path, scratch: Path, release: str | None, arch: str | None
) -> tuple[str, str]:
    """Find the Pro image for the requested Windows release and architecture."""
    message("reading Windows release and architecture from ISO")
    with tempfile.TemporaryDirectory(prefix=".inspect.", dir=scratch) as temporary:
        directory = Path(temporary)
        try:
            subprocess.run(
                [
                    "7z",
                    "e",
                    "-y",
                    f"-o{directory}",
                    str(iso),
                    "sources/install.wim",
                    "sources/install.esd",
                ],
                check=True,
                capture_output=True,
            )
            archives = [path for path in directory.iterdir() if path.is_file()]
            if len(archives) != 1:
                raise ValueError("expected one sources/install.wim or install.esd")
            info = subprocess.run(
                ["wimlib-imagex", "info", str(archives[0]), "--xml"],
                check=True,
                capture_output=True,
            )
            images = ET.fromstring(info.stdout).findall("IMAGE")
        except (
            OSError,
            ValueError,
            ET.ParseError,
            subprocess.CalledProcessError,
        ) as error:
            raise typer.BadParameter(
                "could not read Windows ISO metadata; specify both --release and --arch"
            ) from error

    candidates = set()
    for image in images:
        name = re.fullmatch(r"Windows (10|11) Pro", image.findtext("NAME", ""))
        image_arch = {"9": "amd64", "12": "arm64"}.get(image.findtext("WINDOWS/ARCH"))
        if (
            name
            and image_arch
            and release in (None, name[1])
            and arch in (None, image_arch)
        ):
            candidates.add((name[1], image_arch))
    if len(candidates) != 1:
        reason = "no matching" if not candidates else "multiple matching"
        raise typer.BadParameter(
            f"found {reason} Windows 10/11 Pro targets in the ISO; "
            "check the ISO or specify both --release and --arch"
        )
    return candidates.pop()


def unattended(
    locale: str, username: str, hostname: str, password: str, release: str
) -> str:
    text = (ASSETS / "autounattend.xml").read_text()
    for key, value in {
        "LOCALE": locale,
        "USERNAME": username,
        "HOSTNAME": hostname,
        "RELEASE": release,
        "PASSWORD": password,
    }.items():
        text = text.replace(f"@{key}@", html.escape(value))
    return text


def seed(
    directory: Path,
    drivers: Path,
    locale: str,
    username: str,
    hostname: str,
    password: str,
    release: str,
) -> None:
    directory.mkdir(mode=0o700)
    (directory / "autounattend.xml").write_text(
        unattended(locale, username, hostname, password, release)
    )
    shutil.copyfile(ASSETS / "Finish.ps1", directory / "Finish.ps1")
    target = directory / "drivers"
    target.mkdir()
    for name in (
        "viostor",
        "vioscsi",
        "NetKVM",
        "vioserial",
        "viosock",
        "Balloon",
        "viorng",
        "vioinput",
        "viogpudo",
        "qemufwcfg",
    ):
        # Older catalogs can require an interactive publisher confirmation.
        driver = Path(name) / f"w{release}" / "amd64"
        if (drivers / driver).is_dir():
            shutil.copytree(drivers / driver, target / driver)
    agent = drivers / "guest-agent/qemu-ga-x86_64.msi"
    if not agent.is_file() or not (target / f"viostor/w{release}/amd64").is_dir():
        raise typer.BadParameter(
            f"VirtIO package lacks Windows {release} amd64 drivers or QEMU agent"
        )
    shutil.copyfile(agent, directory / "qemu-ga-x86_64.msi")
    shutil.copyfile(ASSETS / "IncusBootstrap.ps1", directory / "IncusBootstrap.ps1")


def qmp(path: Path, command: dict) -> dict:
    with socket.socket(socket.AF_UNIX) as sock:
        sock.settimeout(5)
        sock.connect(str(path))
        with sock.makefile("rwb") as stream:
            json.loads(stream.readline())  # greeting
            for item in ({"execute": "qmp_capabilities"}, command):
                stream.write(json.dumps(item).encode() + b"\n")
                stream.flush()
                while True:
                    reply = json.loads(stream.readline())
                    if "error" in reply:
                        raise RuntimeError(f"QMP command failed: {reply['error']}")
                    if "return" in reply:
                        break
            return reply


def qemu_path(path: Path) -> str:
    # QEMU parses commas inside drive/chardev options, independently of argv.
    return str(path).replace(",", ",,")


def install(
    target: Path, iso: Path, cpus: int, memory: int, timeout: int, vnc: int | None
) -> None:
    firmware = Path(os.environ["MAINTAIN_WINDOWS_FIRMWARE"])
    variables = Path(os.environ["MAINTAIN_WINDOWS_VARIABLES"])
    shutil.copyfile(variables, target / "OVMF_VARS.fd")
    run(
        ["qemu-img", "create", "-f", "qcow2", str(target / "rootfs.qcow2"), "256G"],
        umask=0o077,
    )
    # QEMU socket names must fit sockaddr_un even when --output is a long path.
    with tempfile.TemporaryDirectory(prefix="maintain-windows.") as temporary:
        work = Path(temporary)
        tpm = subprocess.Popen(
            [
                "swtpm",
                "socket",
                "--tpm2",
                "--tpmstate",
                f"dir={work}",
                "--ctrl",
                f"type=unixio,path={work}/tpm.sock",
                "--flags",
                "not-need-init",
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        vm = None
        try:
            for _ in range(100):
                if (work / "tpm.sock").exists():
                    break
                if tpm.poll() is not None:
                    raise RuntimeError("swtpm exited before creating its socket")
                time.sleep(0.1)
            command = [
                "qemu-system-x86_64",
                "-enable-kvm",
                "-machine",
                "q35,smm=on",
                "-cpu",
                "host",
                "-smp",
                str(cpus),
                "-m",
                str(memory),
                "-display",
                "none",
                "-drive",
                f"if=pflash,format=raw,unit=0,readonly=on,file={qemu_path(firmware)}",
                "-drive",
                f"if=pflash,format=raw,unit=1,file={qemu_path(target / 'OVMF_VARS.fd')}",
                "-global",
                "driver=cfi.pflash01,property=secure,value=on",
                "-drive",
                f"if=none,id=os,format=qcow2,file={qemu_path(target / 'rootfs.qcow2')}",
                "-device",
                "virtio-blk-pci,drive=os,bootindex=1",
                "-drive",
                f"if=none,id=installer,media=cdrom,format=raw,readonly=on,file={qemu_path(iso)}",
                "-device",
                "ide-cd,drive=installer,bus=ide.0,bootindex=2",
                "-drive",
                f"if=none,id=seed,media=cdrom,format=raw,readonly=on,file={qemu_path(target / 'unattended.iso')}",
                "-device",
                "ide-cd,drive=seed,bus=ide.1",
                "-netdev",
                "user,id=net",
                "-device",
                "virtio-net-pci,netdev=net",
                "-device",
                "qemu-xhci",
                "-device",
                "usb-tablet",
                "-vga",
                "std",
                "-chardev",
                f"socket,id=tpm,path={work}/tpm.sock",
                "-tpmdev",
                "emulator,id=tpm,chardev=tpm",
                "-device",
                "tpm-tis,tpmdev=tpm",
                "-device",
                "virtio-serial-pci",
                "-chardev",
                "null,id=agent",
                "-device",
                "virtserialport,chardev=agent,name=org.qemu.guest_agent.0",
                "-serial",
                f"file:{target}/serial.log",
                "-qmp",
                f"unix:{work}/qmp.sock,server=on,wait=off",
            ]
            if vnc is not None:
                command += ["-vnc", f"127.0.0.1:{vnc}"]
                message(f"installer console: vnc://127.0.0.1:{5900 + vnc}")
            with (target / "qemu.log").open("wb") as log:
                vm = subprocess.Popen(command, stdout=log, stderr=log, umask=0o077)
                start = time.monotonic()
                while vm.poll() is None:
                    elapsed = time.monotonic() - start
                    if elapsed > timeout:
                        raise RuntimeError(
                            f"Windows installation timed out; inspect {target}/qemu.log or retry with --vnc-display 1"
                        )
                    # Accept the ISO's initial 'press any key' prompt. On later
                    # reboots the newly installed Windows disk takes precedence.
                    if 5 < elapsed < 20 and (work / "qmp.sock").exists():
                        qmp(
                            work / "qmp.sock",
                            {
                                "execute": "send-key",
                                "arguments": {
                                    "keys": [{"type": "qcode", "data": "ret"}]
                                },
                            },
                        )
                    time.sleep(2)
                if vm.returncode != 0:
                    raise RuntimeError(
                        f"QEMU exited with {vm.returncode}; inspect {target}/qemu.log"
                    )
            serial = target / "serial.log"
            if not serial.exists() or READY not in serial.read_bytes():
                raise RuntimeError(
                    "Windows shut down without completing provisioning; no image was published"
                )
        finally:
            for process in (vm, tpm):
                if process is not None and process.poll() is None:
                    process.terminate()
                    try:
                        process.wait(timeout=15)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.wait()
    run(["qemu-img", "check", str(target / "rootfs.qcow2")])


def metadata(target: Path, locale: str, release: str) -> None:
    data = json.dumps(
        {
            "architecture": "x86_64",
            "creation_date": int(time.time()),
            "properties": {
                "os": "Windows",
                "release": release,
                "description": f"Windows {release} Pro ({locale}), VirtIO",
                "requirements.cdrom_agent": "true",
            },
        }
    ).encode()
    with tarfile.open(target / "metadata.tar.xz", "w:xz") as archive:
        info = tarfile.TarInfo("metadata.yaml")
        info.size = len(data)
        info.mode = 0o644
        archive.addfile(info, io.BytesIO(data))


@app.command()
def image(
    output: Annotated[
        Path | None, typer.Option(help="new private output directory")
    ] = None,
    iso: Annotated[
        Path | None, typer.Option(help="existing official Windows 10 or 11 ISO")
    ] = None,
    iso_url: Annotated[
        str | None,
        typer.Option(help="official Microsoft ISO URL, instead of automatic discovery"),
    ] = None,
    iso_sha256: Annotated[
        str | None, typer.Option(help="expected SHA-256 from Microsoft")
    ] = None,
    release: Annotated[
        Literal["10", "11"] | None,
        typer.Option(help="Windows release; default: detect from ISO"),
    ] = None,
    arch: Annotated[
        Literal["amd64", "arm64"] | None,
        typer.Option(
            help="Windows architecture; default: detect from ISO (builds support amd64)"
        ),
    ] = None,
    locale: Annotated[Literal["zh-CN", "en-US"], typer.Option()] = "en-US",
    username: Annotated[str, typer.Option()] = "Yinfeng",
    password_file: Annotated[
        Path | None,
        typer.Option(
            help="private UTF-8 initial password file; otherwise generate one"
        ),
    ] = None,
    hostname: Annotated[str, typer.Option()] = "ostrich-win",
    cpus: Annotated[int, typer.Option(min=2)] = 4,
    memory: Annotated[
        int, typer.Option(min=4096, help="installer memory in MiB")
    ] = 8192,
    timeout: Annotated[
        int, typer.Option(min=60, help="installation timeout in seconds")
    ] = 5400,
    vnc_display: Annotated[
        int | None,
        typer.Option(min=0, max=99, help="optional localhost-only VNC console"),
    ] = None,
    import_to: Annotated[
        str | None,
        typer.Option(help="optionally import to this Incus remote after building"),
    ] = None,
    alias: Annotated[
        str, typer.Option(help="Incus bootstrap image alias")
    ] = "windows-initial",
) -> None:
    """Download Windows, install unattended locally, and produce an Incus image.

    The initial password is randomly generated in credentials.json (0600), never
    printed or placed in the Nix store. Terraform manages only the eventual VM.
    """
    if iso and iso_url:
        raise typer.BadParameter("use either --iso or --iso-url")
    if release == "10" and not (iso or iso_url):
        raise typer.BadParameter("for Windows 10, supply --iso or --iso-url")
    if arch == "arm64":
        raise typer.BadParameter("Windows ARM64 image builds are not supported yet")
    if not re.fullmatch(r"[A-Za-z][A-Za-z0-9_-]{0,19}", username):
        raise typer.BadParameter(
            "username must be 1-20 ASCII letters, digits, underscores or hyphens"
        )
    if not re.fullmatch(r"[A-Za-z][A-Za-z0-9-]{0,14}", hostname):
        raise typer.BadParameter(
            "hostname must be 1-15 ASCII letters, digits or hyphens"
        )
    if iso_sha256 and not re.fullmatch(r"[a-fA-F0-9]{64}", iso_sha256):
        raise typer.BadParameter("--iso-sha256 must contain 64 hexadecimal digits")
    password = secrets.token_urlsafe(24) + "aA1!"
    if password_file:
        if not password_file.is_file() or password_file.stat().st_mode & 0o077:
            raise typer.BadParameter(
                "--password-file must be a private file (mode 0600)"
            )
        password = password_file.read_text().rstrip("\r\n")
        if not password or "\n" in password or "\r" in password:
            raise typer.BadParameter(
                "--password-file must contain a single nonempty line"
            )
    target = (output or dotfiles_dir() / ".data/windows/windows-image").absolute()
    if target.exists() or target.is_symlink():
        raise typer.BadParameter(f"output already exists: {target}")
    if import_to:
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.-]*", import_to) or not alias:
            raise typer.BadParameter("invalid Incus remote or image alias")
        result = subprocess.run(
            ["incus", "image", "alias", "list", f"{import_to}:", "--format=json"],
            check=True,
            capture_output=True,
            text=True,
        )
        if any(item["name"] == alias for item in json.loads(result.stdout)):
            raise typer.BadParameter(f"image alias already exists: {import_to}:{alias}")
    if platform.machine().lower() not in ("x86_64", "amd64"):
        raise typer.BadParameter(
            "Windows x64 image builds require a local x86_64 KVM host"
        )
    if not os.access("/dev/kvm", os.R_OK | os.W_OK):
        raise typer.BadParameter(
            "the local builder needs read/write access to /dev/kvm"
        )
    for setting in (
        "MAINTAIN_WINDOWS_FIRMWARE",
        "MAINTAIN_WINDOWS_VARIABLES",
        "MAINTAIN_WINDOWS_DRIVERS",
    ):
        if setting not in os.environ:
            raise typer.BadParameter(
                f"{setting} is missing; run the Nix-packaged maintain command"
            )
    for command in ("curl", "xorriso", "swtpm", "qemu-system-x86_64", "qemu-img"):
        if not shutil.which(command):
            raise typer.BadParameter(f"required tool is missing: {command}")
    cache = dotfiles_dir() / ".data/windows/downloads"
    cache.mkdir(parents=True, mode=0o700, exist_ok=True)
    source = iso.absolute() if iso else obtain_iso(cache, locale, iso_url, iso_sha256)
    verify_iso(source, iso_sha256)
    if release is None or arch is None:
        release, arch = discover_iso(source, cache, release, arch)
    if arch != "amd64":
        raise typer.BadParameter("Windows ARM64 image builds are not supported yet")
    target.parent.mkdir(parents=True, exist_ok=True)
    target.mkdir(mode=0o700)
    credentials = target / "credentials.json"
    credentials.write_text(
        json.dumps({"username": username, "password": password}, indent=2) + "\n"
    )
    credentials.chmod(0o600)
    message(
        f"building Windows {release} Pro ({locale}, {arch}); credentials are saved privately in {credentials}"
    )
    with tempfile.TemporaryDirectory(prefix=".seed.", dir=target) as temporary:
        staging = Path(temporary) / "files"
        seed(
            staging,
            Path(os.environ["MAINTAIN_WINDOWS_DRIVERS"]),
            locale,
            username,
            hostname,
            password,
            release,
        )
        run(
            [
                "xorriso",
                "-as",
                "mkisofs",
                "-quiet",
                "-J",
                "-r",
                "-V",
                "MAINTAIN",
                "-o",
                str(target / "unattended.iso"),
                str(staging),
            ],
            umask=0o077,
        )
    install(target, source, cpus, memory, timeout, vnc_display)
    metadata(target, locale, release)
    (target / "manifest.json").write_text(
        json.dumps(
            {
                "os": f"Windows {release} Pro",
                "locale": locale,
                "hostname": hostname,
                "iso_sha256": sha256(source),
                "disk_size": "256GiB",
            },
            indent=2,
        )
        + "\n"
    )
    # The disk is specific to this user/machine, rather than a public sysprep
    # template. Keep its credentials and installation media private too.
    for path in target.iterdir():
        if path.is_file():
            path.chmod(0o600)
    message(f"image ready: {target}")
    if import_to:
        run(
            [
                "incus",
                "image",
                "import",
                str(target / "metadata.tar.xz"),
                str(target / "rootfs.qcow2"),
                f"{import_to}:",
                "--alias",
                alias,
            ]
        )
    else:
        message(
            f"import with: incus image import {target}/metadata.tar.xz {target}/rootfs.qcow2 ostrich-mtls: --alias {alias}"
        )
