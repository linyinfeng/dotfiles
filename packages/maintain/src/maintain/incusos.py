"""Generate IncusOS USB installation images."""

import io
import json
import os
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Annotated, Literal

import typer
from cryptography import x509
from cryptography.x509.oid import ExtendedKeyUsageOID
from rich.filesize import decimal

from maintain.common import data_extract_dir, dotfiles_dir, message, run
from maintain.incusos_secureboot import add_secure_boot_certificates
from maintain.secrets import encrypted_outputs

app = typer.Typer(help="IncusOS installation images")
Architecture = Literal["x86_64-linux", "aarch64-linux"]


def client_ca() -> str:
    """Read the selected public Incus CA, without decrypting any secrets."""
    try:
        data = json.loads((data_extract_dir() / "data.json").read_text())
        generation = data["intermediate_ca_generations"]["incus"]
        pem = data["intermediate_ca_certificates"][generation]
        cert = x509.load_pem_x509_certificate(pem.encode())
        if not cert.extensions.get_extension_for_class(x509.BasicConstraints).value.ca:
            raise ValueError("selected Incus certificate is not a CA")
        usages = cert.extensions.get_extension_for_class(x509.ExtendedKeyUsage).value
        if ExtendedKeyUsageOID.CLIENT_AUTH not in usages:
            raise ValueError("selected Incus CA does not allow client authentication")
        now = datetime.now(timezone.utc)
        if not cert.not_valid_before_utc <= now < cert.not_valid_after_utc:
            raise ValueError("selected Incus CA is not currently valid")
        return pem
    except (OSError, KeyError, ValueError, x509.ExtensionNotFound) as error:
        raise typer.BadParameter(
            f"cannot load public Incus client CA: {error}"
        ) from error


def tailscale_auth_key() -> str:
    """Decrypt only the Terraform Tailscale auth key, keeping it in memory."""
    try:
        result = subprocess.run(
            [
                "sops",
                "--decrypt",
                "--extract",
                '["tailscale_tailnet_key"]["value"]',
                str(encrypted_outputs("pre-nixos")),
            ],
            capture_output=True,
            text=True,
        )
    except OSError as error:
        raise typer.BadParameter(
            "cannot run sops to decrypt Tailscale auth key"
        ) from error
    # Never include captured output in errors: it may contain credentials.
    if result.returncode != 0:
        raise typer.BadParameter(
            f"cannot decrypt Tailscale auth key (sops exit code {result.returncode})"
        )
    key = result.stdout.strip()
    if not key.startswith("tskey-auth-"):
        raise typer.BadParameter("Terraform output is not a Tailscale auth key")
    return key


def validate_hostname(value: str) -> str:
    if not re.fullmatch(r"[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?", value):
        raise typer.BadParameter(
            "hostname must be 1-63 ASCII letters, digits or hyphens, starting and ending with a letter or digit"
        )
    return value


def write_seed(
    path: Path, certificate: str, hostname: str, force_install: bool = False
) -> None:
    """Set management trust and hostname; leave addressing and disks generic."""
    directory = dotfiles_dir() / "packages/incusos-seed"
    try:
        files = {
            path.name: json.loads(path.read_text())
            for path in sorted(directory.glob("*.json"))
        }
        files["install.json"]["force_install"] = force_install
        files["incus.json"]["preseed"]["certificates"] = [
            {
                "name": "incus-client-ca",
                "type": "client",
                "certificate": certificate,
                "restricted": False,
            }
        ]
        files["services.json"]["tailscale"]["auth_key"] = tailscale_auth_key()
        files.setdefault("network.json", {}).setdefault("dns", {})[
            "hostname"
        ] = hostname
    except (OSError, KeyError, ValueError) as error:
        raise typer.BadParameter(
            f"cannot load IncusOS seed configuration: {error}"
        ) from error
    # The seed may contain authentication keys; restrict access before writing.
    with path.open("xb") as output:
        os.fchmod(output.fileno(), 0o600)
        with tarfile.open(
            fileobj=output, mode="w", format=tarfile.USTAR_FORMAT
        ) as archive:
            for name, value in files.items():
                content = json.dumps(value).encode()
                entry = tarfile.TarInfo(name)
                entry.mode = 0o600
                entry.size = len(content)
                archive.addfile(entry, io.BytesIO(content))


@app.command()
def seed(
    hostname: Annotated[
        str,
        typer.Option(
            help="hostname of the installed system", callback=validate_hostname
        ),
    ],
    force_install: Annotated[
        bool,
        typer.Option(
            "--force-install/--no-force-install",
            help="allow the installer to overwrite existing partitions on its target disk",
        ),
    ] = False,
    output: Annotated[
        Path | None,
        typer.Option(help="new seed tar archive; defaults to .data/incusos/seed.tar"),
    ] = None,
) -> None:
    """Generate an architecture-independent install seed without downloading an image."""
    certificate = client_ca()
    target = (output or dotfiles_dir() / ".data/incusos/seed.tar").absolute()
    if target.exists() or target.is_symlink():
        raise typer.BadParameter(f"output already exists: {target}")
    target.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".incusos.", dir=target.parent) as tmp:
        archive = Path(tmp) / "seed.tar"
        write_seed(archive, certificate, hostname, force_install)
        os.link(archive, target)
    message(f"seed ready: {target}")


@app.command()
def image(
    arch: Annotated[Architecture, typer.Option(help="target Nix system architecture")],
    hostname: Annotated[
        str,
        typer.Option(
            help="hostname of the installed system", callback=validate_hostname
        ),
    ],
    force_install: Annotated[
        bool,
        typer.Option(
            "--force-install/--no-force-install",
            help="allow the installer to overwrite existing partitions on its target disk",
        ),
    ] = False,
    output: Annotated[
        Path | None,
        typer.Option(
            help="new .img file; defaults to .data/incusos/incusos-<hostname>-<arch>-<version>.img"
        ),
    ] = None,
) -> None:
    """Download the stable official image and seed it with the Incus client CA.

    Requires Incus 7.6+ in the installed application. Uses DHCP/SLAAC and only
    installs to an unused disk unless --force-install is selected. Does not write devices.
    """
    certificate = client_ca()
    target = output.absolute() if output is not None else None
    if target is not None:
        if target.suffix != ".img":
            raise typer.BadParameter("output must have the .img extension")
        if target.exists() or target.is_symlink():
            raise typer.BadParameter(f"output already exists: {target}")
    directory = (
        target.parent
        if target is not None
        else (dotfiles_dir() / ".data/incusos").absolute()
    )
    directory.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix=".incusos.", dir=directory) as tmp:
        work = Path(tmp)
        seed = work / "seed.tar"
        write_seed(seed, certificate, hostname, force_install)
        message(f"generating stable IncusOS USB image for {arch}...")
        run(
            [
                "flasher-tool",
                "--format",
                "img",
                "--channel",
                "stable",
                "--seed",
                str(seed),
            ],
            cwd=work,
            env=os.environ
            | {"INCUSOS_IMAGE_ARCHITECTURE": arch.removesuffix("-linux")},
        )
        images = list(work.glob("*.img"))
        if len(images) != 1:
            raise typer.BadParameter("flasher-tool did not produce exactly one .img")
        try:
            add_secure_boot_certificates(
                images[0], hostname, dotfiles_dir() / "packages/incusos-secureboot"
            )
        except (OSError, ValueError, subprocess.CalledProcessError) as error:
            raise typer.BadParameter(
                f"cannot prepare Secure Boot enrollment: {error}"
            ) from error
        if target is None:
            version = re.fullmatch(
                r"IncusOS_([A-Za-z0-9][A-Za-z0-9._-]*)\.img", images[0].name
            )
            if version is None:
                raise typer.BadParameter(
                    "cannot determine IncusOS version from downloaded image filename"
                )
            target = directory / f"incusos-{hostname}-{arch}-{version[1]}.img"
            if target.exists() or target.is_symlink():
                raise typer.BadParameter(f"output already exists: {target}")
        # Publish without overwriting an existing file, even if another writer raced us.
        images[0].chmod(0o600)
        os.link(images[0], target)
    message(f"image ready: {target}")


def usb_disk(device: Path) -> dict:
    """Inspect a whole USB disk and refuse devices currently in use."""
    if not device.is_block_device():
        raise typer.BadParameter(f"not a block device: {device}")
    result = subprocess.run(
        [
            "lsblk",
            "--json",
            "--bytes",
            "--paths",
            "--output",
            "NAME,TYPE,TRAN,SIZE,RO,MODEL,SERIAL,PARTLABEL,MOUNTPOINTS",
            str(device),
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    disks = json.loads(result.stdout)["blockdevices"]
    if len(disks) != 1 or disks[0]["name"] != str(device):
        raise typer.BadParameter("cannot identify a unique target disk")
    disk = disks[0]
    if disk["type"] != "disk" or disk.get("tran") != "usb":
        raise typer.BadParameter("target must be a whole USB disk, not a partition")

    def unused(node: dict) -> None:
        if node.get("ro"):
            raise typer.BadParameter(f"device is read-only: {node['name']}")
        if any(node.get("mountpoints") or []):
            raise typer.BadParameter(
                f"unmount mounted filesystems or disable swap on {node['name']} first"
            )
        for child in node.get("children", []):
            if child["type"] != "part":
                raise typer.BadParameter(
                    f"device has an active block mapping: {child['name']}"
                )
            unused(child)

    unused(disk)
    return disk


def flash_destination(disk: dict, seed_only: bool) -> dict:
    if not seed_only:
        return disk
    partitions = [
        child
        for child in disk.get("children", [])
        if child.get("type") == "part" and child.get("partlabel") == "seed-data"
    ]
    if len(partitions) != 1:
        raise typer.BadParameter("expected exactly one existing seed-data partition")
    return partitions[0]


@app.command()
def flash(
    device: Annotated[
        Path,
        typer.Argument(
            help="whole USB disk, e.g. /dev/disk/by-id/usb-...", readable=False
        ),
    ],
    image: Annotated[
        Path | None,
        typer.Option(help="complete .img to write to the whole disk", readable=False),
    ] = None,
    seed: Annotated[
        Path | None,
        typer.Option(
            help="seed tar to write only to the existing seed-data partition",
            readable=False,
        ),
    ] = None,
    yes: Annotated[
        bool, typer.Option("--yes", "-y", help="skip the erase confirmation")
    ] = False,
) -> None:
    """Flash an image or seed partition, automatically using run0 when not root."""
    if (image is None) == (seed is None):
        raise typer.BadParameter("specify exactly one of --image or --seed")
    if os.geteuid() != 0:
        run0 = shutil.which("run0")
        if run0 is None:
            raise typer.BadParameter("run0 is required to flash as a non-root user")
        # Expand paths before elevation: run0 starts with a fresh environment.
        command = [
            run0,
            "--",
            str(Path(sys.argv[0]).resolve()),
            "incusos",
            "flash",
            str(device.absolute()),
            "--image" if image is not None else "--seed",
            str((image if image is not None else seed).absolute()),
        ]
        if yes:
            command.append("--yes")
        try:
            run(command)
        except subprocess.CalledProcessError as error:
            raise typer.Exit(error.returncode) from error
        return
    try:
        source = (image if image is not None else seed).resolve(strict=True)
        device = device.resolve(strict=True)
    except OSError as error:
        raise typer.BadParameter(str(error)) from error
    if not source.is_file() or source.stat().st_size == 0:
        raise typer.BadParameter("source must be a non-empty regular file")
    if image is not None:
        if source.suffix != ".img":
            raise typer.BadParameter("image must have the .img extension")
        with source.open("rb") as stream:
            stream.seek(512)
            if stream.read(8) != b"EFI PART":
                raise typer.BadParameter("image must contain a GPT partition table")
    else:
        try:
            with tarfile.open(source) as archive:
                names = archive.getnames()
                if "install.json" not in names or "incus.json" not in names:
                    raise ValueError("missing install.json or incus.json")
        except (OSError, ValueError, tarfile.TarError) as error:
            raise typer.BadParameter(
                "source is not an IncusOS installation seed tar"
            ) from error

    disk = usb_disk(device)
    destination = flash_destination(disk, seed is not None)
    size = source.stat().st_size
    if size > int(destination["size"]):
        raise typer.BadParameter("source is larger than the destination")
    message(
        f"USB disk: {device}, model={disk.get('model')}, serial={disk.get('serial')}, size={decimal(int(disk['size']))}"
    )
    message(f"write {source} ({decimal(size)}) to {destination['name']}")
    if not yes:
        typer.confirm(
            f"Erase {'the seed partition on' if seed is not None else 'ALL data on'} {device}?",
            abort=True,
        )
    # Recheck after the prompt in case the device was removed, replaced or mounted.
    if usb_disk(device) != disk:
        raise typer.BadParameter("target device changed; inspect it and retry")

    def execute(command: str, *args: str) -> None:
        run([shutil.which(command) or command, *args])

    execute(
        "dd",
        f"if={source}",
        f"of={destination['name']}",
        "bs=4M",
        "status=progress",
        "conv=fsync,notrunc",
    )
    execute("cmp", "--bytes", str(size), str(source), destination["name"])
    if image is not None:
        execute("blockdev", "--rereadpt", str(device))
    message(f"flash verified: {destination['name']}")
