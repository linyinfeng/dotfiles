"""Maintenance tasks that used to be ad-hoc shell in the devshell."""

import subprocess
import sys
from pathlib import Path

import typer

app = typer.Typer(help="maintenance CLI for this repository")
secrets = typer.Typer(help="sops encrypted files")
app.add_typer(secrets, name="secrets")


def repo_root() -> Path:
    """The checkout this runs in, independent of the current directory."""
    out = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
        check=True,
    )
    return Path(out.stdout.strip())


def sops_files(root: Path) -> list[Path]:
    return sorted((root / "secrets").rglob("*.yaml"))


@secrets.command("update-keys")
def update_keys() -> None:
    """Re-wrap every sops file for the current recipient set."""
    root = repo_root()
    files = sops_files(root)
    for path in files:
        print(f"> updating {path.relative_to(root)}", file=sys.stderr)
        subprocess.run(["sops", "updatekeys", "--yes", str(path)], check=True)
    print(f"> {len(files)} file(s)", file=sys.stderr)


def main() -> None:
    app()
