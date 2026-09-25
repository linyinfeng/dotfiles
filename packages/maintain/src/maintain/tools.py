"""The remaining devshell tasks: boot images, patches, and new hosts."""

import subprocess
import tempfile
from pathlib import Path
from typing import Annotated

import typer

from maintain.common import dotfiles_dir, message, run

boot_sd = typer.Typer(help="boot images on SD cards")
patches = typer.Typer(help="patches/")
prepare = typer.Typer(help="adding hosts to this repository")

HOST_TEMPLATE = """{
  lib,
  ...
}: {
  world.suites.server.enable = lib.mkDefault true;
  # PLACEHOLDER profile gates

  config = lib.mkMerge [
    {
      # PLACEHOLDER
    }

    # stateVersion
    {
      system.stateVersion = "STATE_VERSION";
    }
  ];
}
"""


def captured(cmd: list[str], **kwargs: object) -> str:
    return subprocess.run(
        cmd, capture_output=True, text=True, check=True, **kwargs
    ).stdout.strip()


def insert_before(path: Path, anchor: str, block: str) -> None:
    """Insert BLOCK before the ANCHOR line, the way the host templates expect to be extended."""
    lines = path.read_text().splitlines(keepends=True)
    for index, line in enumerate(lines):
        if line.strip() == anchor:
            lines.insert(index, block)
            break
    else:
        message(f"no {anchor!r} anchor in {path}")
        raise typer.Exit(2)
    path.write_text("".join(lines))


@boot_sd.command("write")
def write(
    name: Annotated[str, typer.Argument(help="host whose boot image to write")],
    ssh_args: Annotated[
        list[str], typer.Argument(help="arguments for ssh, e.g. root@host")
    ],
) -> None:
    """Build NAME's boot image and write it to /firmware/boot.sd on the target."""
    flake = f"{dotfiles_dir()}#nixosConfigurations.{name}.config.system.build.bootsd"
    image = captured(["nix", "build", flake, "--no-link", "--print-out-paths"])
    run(["sha1sum", image])
    with open(image, "rb") as image_file:
        run(
            ["ssh", *ssh_args, "dd of=/firmware/boot.sd\nsha1sum /firmware/boot.sd"],
            stdin=image_file,
        )
    run(["sync"])


@patches.command("update")
def update() -> None:
    """Refresh patches/ (nothing to do until an upstream patch is added)."""
    message("updating patches...")
    (dotfiles_dir() / "patches").mkdir(exist_ok=True)


@prepare.command("new-host")
def new_host(host: str, system: str) -> None:
    """Create a new host's files, its age key, and a notice with the manual steps."""
    root = dotfiles_dir()
    state_version = captured(["nix", "eval", f"{root}#libs.flakeStateVersion", "--raw"])

    message("creating host directory...")
    (root / "nixos/hosts" / host).mkdir(parents=True, exist_ok=True)

    message("creating default.nix...")
    (root / "nixos/hosts" / host / "default.nix").write_text(
        HOST_TEMPLATE.replace("STATE_VERSION", state_version)
    )

    message("creating host in nix file...")
    insert_before(
        root / "flake/hosts.nix",
        "# PLACEHOLDER new host",
        f'(mkHost {{\n  name = "{host}";\n  system = "{system}";\n}})\n',
    )

    message("creating host in terraform file...")
    insert_before(
        root / "terraform/stages/pre-nixos/hosts.tf",
        "# PLACEHOLDER new host",
        f"{host} = {{\n  records      = {{}}\n  ddns_records = {{}}\n"
        "  host_indices = []\n  endpoints_v4 = []\n  endpoints_v6 = []\n}\n",
    )

    with tempfile.TemporaryDirectory(prefix="encrypt.") as tmp:
        message("creating new age key pair...")
        key = Path(tmp) / "key"
        run(["age-keygen", "--output", str(key)])
        identity = captured(["age-keygen", "-y", str(key)])

        message("updating nixago configuration...")
        insert_before(
            root / "nixago/sops-yaml.nix",
            "# PLACEHOLDER new host",
            f'{host} = {{\n  key = "{identity}";\n  owned = true;\n}};\n',
        )

        message("formatting...")
        run(["nix", "fmt"], cwd=root)

        message("git add...")
        run(["git", "add", "--all"], cwd=root)

        message("creating notice...")
        notice = root / f"prepare-host-notice-{host}"
        notice.write_text(
            f"age key\n=======\n{key.read_text()}\n"
            "manual run\n==========\nmaintain terraform pipe-all\nmaintain secrets update-keys\n"
        )

    message(f"notice saved in '{notice.name}'")
    print(notice.read_text())
