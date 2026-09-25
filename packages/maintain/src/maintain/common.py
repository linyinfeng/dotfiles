"""Repository layout, subprocess helpers, and the messages the pipelines report."""

import os
import subprocess
import sys
from collections.abc import Callable
from pathlib import Path


def message(text: str) -> None:
    print(f"> {text}", file=sys.stderr)


def run(cmd: list[str], **kwargs: object) -> None:
    subprocess.run(cmd, check=True, **kwargs)


def repo_root() -> Path:
    """The checkout this runs in, independent of the current directory."""
    out = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
        check=True,
    )
    return Path(out.stdout.strip())


def env_path(name: str, default: Callable[[], Path]) -> Path:
    """$NAME made absolute, or the default. CI passes these relative to its workspace root."""
    value = os.environ.get(name)
    return Path(value).resolve() if value else default()


def dotfiles_dir() -> Path:
    return env_path("DOTFILES_DIR", repo_root)


def secrets_dir() -> Path:
    return env_path(
        "SECRETS_DIR", lambda: repo_root().parent / "infrastructure-secrets"
    )


def secrets_extract_dir() -> Path:
    return env_path("SECRETS_EXTRACT_DIR", lambda: repo_root() / "secrets")


def terraform_dir() -> Path:
    return env_path("TERRAFORM_DIR", lambda: dotfiles_dir() / "terraform")


def data_extract_dir() -> Path:
    return env_path("DATA_EXTRACT_DIR", lambda: dotfiles_dir() / "lib/data")


def nix_build(flake_ref: str, out_link: Path) -> None:
    run(["nix", "build", flake_ref, "--out-link", str(out_link)])
