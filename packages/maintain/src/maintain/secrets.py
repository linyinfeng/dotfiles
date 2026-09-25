"""sops handling: key updates, encryption, and the extracted secret trees."""

import os
import shlex
import shutil
import subprocess
import sys
import tempfile
from collections.abc import Callable
from pathlib import Path
from typing import Annotated, Literal

import typer

app = typer.Typer(help="sops encrypted files")

SecretType = Literal["terraform", "predefined", "both"]


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


def extract_dir() -> Path:
    return env_path("SECRETS_EXTRACT_DIR", lambda: repo_root() / "secrets")


def sops_files(root: Path) -> list[Path]:
    return sorted((root / "secrets").rglob("*.yaml"))


def nix_build(flake_ref: str, out_link: Path) -> None:
    run(["nix", "build", flake_ref, "--out-link", str(out_link)])


def decrypt(source: Path, target: Path) -> None:
    """Decrypt SOURCE into TARGET, which the caller keeps inside a private temp directory."""
    with target.open("w") as out:
        run(
            [
                "sops",
                "--input-type",
                "yaml",
                "--output-type",
                "yaml",
                "--decrypt",
                str(source),
            ],
            stdout=out,
        )


def encrypt_to_file(plain: Path, target: Path, type: str, formatter: str) -> None:
    """Encrypt PLAIN into TARGET, skipping when the formatted content is unchanged."""
    argv = shlex.split(formatter)
    if target.exists():
        with tempfile.TemporaryDirectory(prefix="encrypt.") as tmp:
            tmpdir = Path(tmp)
            decrypted = tmpdir / "target_plain"
            decrypt(target, decrypted)
            formatted = []
            for source in (decrypted, plain):
                path = tmpdir / f"{source.name}.formatted"
                with path.open("w") as out:
                    run([*argv, str(source)], stdout=out)
                formatted.append(path.read_bytes())
            if formatted[0] == formatted[1]:
                message(f"same, skipping '{target}'...")
                return

    # sops runs $EDITOR on a temporary copy of the plaintext; copying the new plaintext
    # over it is how this repository writes secrets without an interactive editor.
    env = os.environ | {"EDITOR": f"cp {shlex.quote(str(plain))}"}
    run(["sops", "--input-type", type, "--output-type", type, str(target)], env=env)
    run(["prettier", "--write", str(target)])


def extract_file(source: Path, secret_type: str) -> None:
    """Render the SECRET_TYPE templates from a decrypted SOURCE into the secrets tree."""
    target_dir = extract_dir() / secret_type / "hosts"
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
                plain, target_dir / f"{name}.yaml", "yaml", "yq --prettyPrint"
            )


@app.command("update-keys")
def update_keys() -> None:
    """Re-wrap every sops file for the current recipient set."""
    root = repo_root()
    files = sops_files(root)
    for path in files:
        message(f"updating {path.relative_to(root)}")
        run(["sops", "updatekeys", "--yes", str(path)])
    message(f"{len(files)} file(s)")


@app.command("encrypt-to")
def encrypt_to(
    plain: Annotated[Path, typer.Argument(help="plaintext file to encrypt")],
    target: Annotated[
        Path, typer.Option("--target", "-t", help="encrypted file to write")
    ],
    type: Annotated[str, typer.Option(help="sops input and output type")] = "yaml",
    formatter: Annotated[
        str,
        typer.Option(
            help="command that formats one file to stdout, e.g. 'yq --prettyPrint'"
        ),
    ] = "",
) -> None:
    """Encrypt PLAIN into TARGET, skipping when the formatted content is unchanged."""
    message(
        f"encrypting '{plain}' to '{target}' (type: '{type}', formatter: '{formatter}')..."
    )
    encrypt_to_file(plain, target, type, formatter)


@app.command("extract")
def extract(secret_type: Annotated[SecretType, typer.Argument()] = "both") -> None:
    """Regenerate the extracted secrets from the encrypted sources."""
    with tempfile.TemporaryDirectory(prefix="encrypt.") as tmp:
        tmpdir = Path(tmp)

        if secret_type in ("terraform", "both"):
            outputs = secrets_dir() / "terraform/outputs/pre-nixos.yaml"
            if not outputs.exists():
                outputs = secrets_dir() / "terraform-outputs.yaml"
            source = tmpdir / "terraform.yaml"
            decrypt(outputs, source)
            extract_file(source, "terraform")

        if secret_type in ("predefined", "both"):
            source = tmpdir / "predefined.yaml"
            decrypt(secrets_dir() / "predefined.yaml", source)
            extract_file(source, "predefined")
