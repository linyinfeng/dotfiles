"""Generate reusable IncusOS USB installation images."""

import io
import json
import os
import tarfile
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Annotated, Literal

import typer
from cryptography import x509
from cryptography.x509.oid import ExtendedKeyUsageOID

from maintain.common import data_extract_dir, dotfiles_dir, message, run

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


def write_seed(path: Path, certificate: str) -> None:
    """Trust only the dedicated client CA; leave addressing and disks generic."""
    files = {
        "install.json": {},
        "applications.json": {"applications": [{"name": "incus"}]},
        "incus.json": {
            "apply_defaults": True,
            "preseed": {
                "certificates": [
                    {
                        "name": "incus-client-ca",
                        "type": "client",
                        "certificate": certificate,
                        "restricted": False,
                    }
                ]
            },
        },
    }
    with tarfile.open(path, "w", format=tarfile.USTAR_FORMAT) as archive:
        for name, value in files.items():
            content = json.dumps(value).encode()
            entry = tarfile.TarInfo(name)
            entry.mode = 0o600
            entry.size = len(content)
            archive.addfile(entry, io.BytesIO(content))


@app.command()
def seed(
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
        write_seed(archive, certificate)
        os.link(archive, target)
    message(f"seed ready: {target}")


@app.command()
def image(
    arch: Annotated[Architecture, typer.Option(help="target Nix system architecture")],
    output: Annotated[
        Path | None, typer.Option(help="new .img file; defaults to .data/incusos/")
    ] = None,
) -> None:
    """Download the stable official image and seed it with the Incus client CA.

    Requires Incus 7.6+ in the installed application. Uses DHCP/SLAAC and only
    installs to an unused disk; no forced overwrites or device writes.
    """
    certificate = client_ca()
    target = (
        output or dotfiles_dir() / ".data/incusos" / f"incusos-{arch}.img"
    ).absolute()
    if target.suffix != ".img":
        raise typer.BadParameter("output must have the .img extension")
    if target.exists() or target.is_symlink():
        raise typer.BadParameter(f"output already exists: {target}")
    target.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix=".incusos.", dir=target.parent) as tmp:
        work = Path(tmp)
        seed = work / "seed.tar"
        write_seed(seed, certificate)
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
        # Publish without overwriting an existing file, even if another writer raced us.
        os.link(images[0], target)
    message(f"image ready: {target}")
