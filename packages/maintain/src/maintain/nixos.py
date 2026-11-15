"""Build NixOS disk images with bootstrap identities injected at runtime."""

import os
import stat
import subprocess
import tempfile
from pathlib import Path
from typing import Annotated

import typer

from maintain.common import dotfiles_dir, message, nix_build, run
from maintain.secrets import host_key_path

app = typer.Typer(help="NixOS installation images")


@app.command()
def image(
    host: Annotated[str, typer.Argument(help="NixOS host configuration")],
    output: Annotated[
        Path | None,
        typer.Option(help="new output directory; defaults to .data/nixos/<host>-image"),
    ] = None,
) -> None:
    """Create Disko images, injecting the standard host age key outside the Nix store."""
    key = host_key_path(host)
    if not key.is_file():
        raise typer.BadParameter(
            f"host key is missing: {key}; run maintain secrets generate-host-key {host}"
        )
    if key.stat().st_mode & 0o077:
        raise typer.BadParameter(
            f"host key must not be accessible to group or others: {key}"
        )

    root = dotfiles_dir()
    target = (output or root / ".data/nixos" / f"{host}-image").absolute()
    if target.exists() or target.is_symlink():
        raise typer.BadParameter(f"output already exists: {target}")

    configuration = f"{root}#nixosConfigurations.{host}.config"
    key_target = subprocess.run(
        ["nix", "eval", "--raw", f"{configuration}.sops.age.keyFile"],
        stdout=subprocess.PIPE,
        text=True,
        check=True,
    ).stdout.strip()
    destination = Path(key_target)
    if (
        not destination.is_absolute()
        or destination == Path("/")
        or ".." in destination.parts
    ):
        raise typer.BadParameter("sops.age.keyFile must be an absolute file path")

    target.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".nixos.", dir=target.parent) as tmp:
        builder = Path(tmp) / "builder"
        nix_build(f"{configuration}.system.build.diskoImagesScript", builder)
        # Reserve the output exclusively and protect the disk from its first write.
        target.mkdir(mode=0o700)
        message(f"creating {host} disk images with the host identity at {key_target}")
        build_env = os.environ.copy()
        build_env.setdefault("NIX_BUILD_CORES", str(os.cpu_count() or 1))
        run(
            [str(builder), "--post-format-files", str(key), key_target],
            cwd=target,
            umask=0o077,
            env=build_env,
        )

    disks = [path for path in target.iterdir() if path.suffix in (".raw", ".qcow2")]
    if not disks:
        raise typer.BadParameter(f"Disko produced no disk images in {target}")
    for path in target.rglob("*"):
        mode = path.lstat().st_mode
        if stat.S_ISREG(mode):
            os.chmod(path, 0o600)
        elif stat.S_ISDIR(mode):
            os.chmod(path, 0o700)
    message(f"image ready: {target}")
