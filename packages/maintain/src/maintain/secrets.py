"""sops handling: key updates, encryption, and the extracted secret trees."""

import os
import shlex
import shutil
import sys
import tempfile
from pathlib import Path
from typing import Annotated, Literal

import typer

from maintain.common import (
    dotfiles_dir,
    env_path,
    message,
    nix_build,
    run,
    secrets_dir,
    secrets_extract_dir,
)

app = typer.Typer(help="sops encrypted files")

SecretType = Literal["terraform", "predefined", "both"]


def sops_config() -> Path:
    return env_path("MAINTAIN_SOPS_CONFIG", lambda: dotfiles_dir() / ".sops.yaml")


def infrastructure_sops_files(root: Path) -> list[Path]:
    """Only encrypted inputs, outputs and state, including the legacy layout."""
    patterns = [
        "predefined.yaml",
        "terraform-inputs.yaml",
        "terraform/outputs/*.yaml",
        "terraform/states/*.tfstate",
        "terraform-outputs.yaml",
        "terraform.tfstate",
        "terraform.plan",
    ]
    return sorted(
        {path for pattern in patterns for path in root.glob(pattern) if path.is_file()}
    )


def decrypt(source: Path, target: Path, type: str = "yaml") -> None:
    """Decrypt SOURCE into TARGET, which callers keep inside a private temp directory."""
    fd = os.open(target, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as out:
        os.fchmod(out.fileno(), 0o600)
        run(
            [
                "sops",
                "--input-type",
                type,
                "--output-type",
                type,
                "--decrypt",
                str(source),
            ],
            stdout=out,
        )


def encrypt_to_file(plain: Path, target: Path, type: str, formatter: list[str]) -> None:
    """Encrypt PLAIN into TARGET, skipping when the formatted content is unchanged."""
    if target.exists():
        with tempfile.TemporaryDirectory(prefix="encrypt.") as tmp:
            tmpdir = Path(tmp)
            decrypted = tmpdir / "target_plain"
            decrypt(target, decrypted, type)
            formatted = []
            for source in (decrypted, plain):
                path = tmpdir / f"{source.name}.formatted"
                with path.open("w") as out:
                    run([*formatter, str(source)], stdout=out)
                formatted.append(path.read_bytes())
            if formatted[0] == formatted[1]:
                message(f"same, skipping '{target}'...")
                return

    # sops runs $EDITOR on a temporary copy of the plaintext; copying the new plaintext
    # over it is how this repository writes secrets without an interactive editor.
    env = os.environ | {"EDITOR": f"cp {shlex.quote(str(plain))}"}
    run(
        [
            "sops",
            "--config",
            str(sops_config()),
            "--input-type",
            type,
            "--output-type",
            type,
            str(target),
        ],
        env=env,
    )
    run(["prettier", "--write", str(target)])


def extract_file(source: Path, secret_type: str) -> None:
    """Render the SECRET_TYPE templates from a decrypted SOURCE into the secrets tree."""
    target_dir = secrets_extract_dir() / secret_type / "hosts"
    target_dir.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="encrypt.") as tmp:
        tmpdir = Path(tmp)
        input_file = tmpdir / "input.yaml"
        shutil.copy(source, input_file)

        message("creating templates...")
        templates = tmpdir / "templates"
        nix_build(f"{dotfiles_dir()}#secrets-templates/{secret_type}", templates)

        message("getting host names...")
        host_names = tmpdir / "host-names"
        nix_build(f"{dotfiles_dir()}#host-names", host_names)

        for name in host_names.read_text().split():
            message(f"extracting '{secret_type}/hosts/{name}.yaml'...")
            plain = tmpdir / f"{name}.plain.yaml"
            with plain.open("w") as out:
                run(
                    [
                        "yq",
                        "eval",
                        "--from-file",
                        str(templates / f"{name}.yq"),
                        str(input_file),
                    ],
                    stdout=out,
                )
            encrypt_to_file(
                plain, target_dir / f"{name}.yaml", "yaml", ["yq", "--prettyPrint"]
            )


def encrypted_outputs(stage: str = "pre-nixos") -> Path:
    """The encrypted terraform outputs of STAGE, with the pre-split layout as fallback."""
    outputs = secrets_dir() / f"terraform/outputs/{stage}.yaml"
    if (
        not outputs.exists()
        and (legacy := secrets_dir() / "terraform-outputs.yaml").exists()
    ):
        return legacy
    return outputs


@app.command("update-keys")
def update_keys() -> None:
    """Re-wrap the host secrets and infrastructure sources for current recipients."""
    infrastructure = secrets_dir()
    if not infrastructure.is_dir():
        raise typer.BadParameter(f"secrets directory does not exist: {infrastructure}")
    files = sorted(
        set(secrets_extract_dir().rglob("*.yaml"))
        | set(infrastructure_sops_files(infrastructure))
    )
    for path in files:
        message(f"updating {path}")
        run(
            [
                "sops",
                "--config",
                str(sops_config()),
                "updatekeys",
                "--yes",
                str(path),
            ]
        )
    message(f"{len(files)} file(s)")


@app.command("extract")
def extract(secret_type: Annotated[SecretType, typer.Argument()] = "both") -> None:
    """Regenerate the extracted secrets and format the repository."""
    extract_sources(secret_type)
    run(["nix", "fmt"], cwd=dotfiles_dir())


def extract_sources(secret_type: SecretType) -> None:
    """Extract without formatting, for pipelines that format once at the end."""
    with tempfile.TemporaryDirectory(prefix="encrypt.") as tmp:
        tmpdir = Path(tmp)

        if secret_type in ("terraform", "both"):
            source = tmpdir / "terraform.yaml"
            decrypt(encrypted_outputs("pre-nixos"), source)
            extract_file(source, "terraform")

        if secret_type in ("predefined", "both"):
            source = tmpdir / "predefined.yaml"
            decrypt(secrets_dir() / "predefined.yaml", source)
            extract_file(source, "predefined")
