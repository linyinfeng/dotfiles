"""terraform pipelines: one encrypted state per stage, plus their outputs."""

import json
import os
import signal
import string
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import IO, Annotated

import typer

from maintain import secrets
from maintain.common import (
    data_extract_dir,
    dotfiles_dir,
    message,
    run,
    secrets_dir,
    terraform_dir,
)

app = typer.Typer(help="terraform stage pipelines")


_registry: dict | None = None


def reset_registry() -> None:
    global _registry
    _registry = None


def registry() -> dict:
    """The stage registry Nix generated at build time: stages -> TF_VAR_* defaults, plus their order."""
    global _registry
    if _registry is None:
        path = os.environ.get("MAINTAIN_STAGE_REGISTRY")
        if not path:
            message(
                "MAINTAIN_STAGE_REGISTRY is not set: run the packaged maintain,"
                " or point it at the terraform-stages.json Nix generated"
            )
            raise typer.Exit(2)
        _registry = json.loads(Path(path).read_text())
    return _registry


def stage_from(args: list[str]) -> tuple[str, list[str]]:
    """Split a leading stage argument (which wins over $TERRAFORM_STAGE) from terraform's own args."""
    stages = registry()["stages"]
    given = bool(args) and args[0] in stages
    stage = args[0] if given else os.environ.get("TERRAFORM_STAGE", "")

    if not stage:
        message(
            "no terraform stage given: pass it as the first argument (e.g. pre-nixos) or set TERRAFORM_STAGE"
        )
        raise typer.Exit(2)
    if stage not in stages:
        message(f"unknown terraform stage: {stage}")
        raise typer.Exit(2)

    return stage, args[1:] if given else args


def stage_root(stage: str) -> Path:
    root = terraform_dir() / "stages" / stage
    if not root.is_dir():
        message(f"terraform root does not exist for stage: {stage}")
        raise typer.Exit(2)
    return root.resolve()


def stage_env(stage: str) -> dict[str, str]:
    """The stage's TF_VAR_* values: an explicit override wins, the other stages' are dropped."""
    stages = registry()["stages"]
    env = dict(os.environ)
    # terraform runs with -chdir, so every path it receives must be absolute; CI passes
    # SECRETS_DIR relative to its workspace root, so resolve it before expanding the defaults
    env["SECRETS_DIR"] = str(secrets_dir())
    for var in {v for defaults in stages.values() for v in defaults} - set(
        stages[stage]
    ):
        env.pop(f"TF_VAR_{var}", None)
    for var, default in stages[stage].items():
        env[f"TF_VAR_{var}"] = os.environ.get(f"TF_VAR_{var}") or string.Template(
            default
        ).substitute(env)
    return env


def encrypted_state(stage: str) -> Path:
    """The stage's encrypted state, falling back to the pre-split layout of pre-nixos."""
    state = secrets_dir() / f"terraform/states/{stage}.tfstate"
    legacy = secrets_dir() / "terraform.tfstate"
    if not state.exists() and stage == "pre-nixos" and legacy.exists():
        message("using legacy encrypted state for pre-nixos")
        return legacy
    return state


def terraform_run(stage: str, args: list[str], stdout: IO[str] | None = None) -> None:
    """Run terraform in STAGE, decrypting its state first and re-encrypting it afterwards."""
    root = stage_root(stage)
    env = stage_env(stage)
    env["TF_DATA_DIR"] = str(root / ".terraform-data")

    encrypted = encrypted_state(stage)
    plain = root / "terraform.tfstate"
    message(f"decrypt terraform state to '{plain}'...")
    if not encrypted.exists():
        message(f"encrypted state is missing: {encrypted}")
        message("refusing to run Terraform without an explicitly migrated state")
        raise typer.Exit(2)
    secrets.decrypt(encrypted, plain, "json")

    # the state must be re-encrypted and wiped even when terraform fails or is interrupted
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(143))
    code = 0
    try:
        code = subprocess.run(
            ["terraform", f"-chdir={root}", *args], env=env, stdout=stdout
        ).returncode
    except KeyboardInterrupt:
        code = 130
    finally:
        if plain.exists() and plain.stat().st_size:
            secrets.encrypt_to_file(plain, encrypted, "json", ["yq", "--prettyPrint"])
        message(f"deleting terraform state '{plain}'...")
        for stale in plain.parent.glob(f"{plain.name}*"):
            stale.unlink()
        message(f"terraform exit code: {code}")
    if code:
        raise typer.Exit(code)


@app.command("init")
def init(
    args: Annotated[
        list[str], typer.Argument(help="<stage> and terraform init arguments")
    ] = [],
) -> None:
    """Initialize one stage (its state lives encrypted in the secrets repository)."""
    stage, rest = stage_from(args)
    root = stage_root(stage)
    run(
        [
            "terraform",
            f"-chdir={root}",
            "init",
            f"-backend-config=path={root}/terraform.tfstate",
            *rest,
        ],
        env=os.environ | {"TF_DATA_DIR": str(root / ".terraform-data")},
    )


@app.command("run")
def run_terraform(
    args: Annotated[
        list[str], typer.Argument(help="<stage> and terraform arguments")
    ] = [],
) -> None:
    """Run any terraform subcommand in a stage, its state handled automatically."""
    stage, rest = stage_from(args)
    terraform_run(stage, rest)


@app.command("update-outputs")
def update_outputs(
    args: Annotated[
        list[str], typer.Argument(help="<stage> and terraform output arguments")
    ] = [],
) -> None:
    """Store the stage outputs encrypted in the secrets repository."""
    stage, rest = stage_from(args)
    with tempfile.TemporaryDirectory(prefix="encrypt.") as tmp:
        plain_output = Path(tmp) / "terraform-outputs.plain.yaml"
        with plain_output.open("w") as out:
            terraform_run(stage, ["output", "--json", *rest], stdout=out)
        outputs = secrets_dir() / f"terraform/outputs/{stage}.yaml"
        outputs.parent.mkdir(parents=True, exist_ok=True)
        secrets.encrypt_to_file(plain_output, outputs, "yaml", ["yq", "--prettyPrint"])


@app.command("extract-data")
def extract_data() -> None:
    """Render lib/data/data.json from the pre-nixos outputs (the NixOS inputs)."""
    target = data_extract_dir() / "data.json"
    with tempfile.TemporaryDirectory(prefix="encrypt.") as tmp:
        source = Path(tmp) / "outputs.yaml"
        secrets.decrypt(secrets.encrypted_outputs("pre-nixos"), source)
        message(f"creating '{target.name}'...")
        with target.open("w") as out:
            run(
                [
                    "yq",
                    "eval",
                    "--from-file",
                    str(data_extract_dir() / "template.yq"),
                    str(source),
                    "--output-format",
                    "json",
                ],
                stdout=out,
            )


@app.command("commit-outputs")
def commit_outputs(
    message_: Annotated[str, typer.Argument(help="commit message")],
) -> None:
    """Commit and push whatever the pipeline wrote into the secrets repository."""
    secrets_repo = str(secrets_dir())
    run(["git", "-C", secrets_repo, "add", "--all"])
    if (
        subprocess.run(
            ["git", "-C", secrets_repo, "diff", "--cached", "--quiet"]
        ).returncode
        == 0
    ):
        message("secrets repository is clean, nothing to commit")
        return
    run(["git", "-C", secrets_repo, "commit", "--message", message_])
    run(["git", "-C", secrets_repo, "push"])


def apply_stage(stage: str, args: list[str]) -> None:
    """init, apply, refresh the outputs, and feed the NixOS inputs from pre-nixos."""
    init([stage])
    terraform_run(stage, ["apply", *args])
    update_outputs([stage])
    if stage == "pre-nixos":
        extract_data()
        secrets.extract("terraform")


@app.command("apply-stage")
def apply_stage_command(
    args: Annotated[
        list[str], typer.Argument(help="<stage> and terraform apply arguments")
    ] = [],
) -> None:
    """Initialize, apply and publish one stage."""
    stage, rest = stage_from(args)
    apply_stage(stage, rest)


@app.command("pipe")
def pipe(
    args: Annotated[
        list[str], typer.Argument(help="<stage> and terraform apply arguments")
    ] = [],
) -> None:
    """Apply one stage and, when it succeeded, commit its outputs and format the repository."""
    stage, rest = stage_from(args)
    run(["git", "-C", str(secrets_dir()), "pull", "--ff-only"])
    apply_stage(stage, rest)
    commit_outputs(f"Terraform {stage} apply")
    run(["nix", "fmt"], cwd=dotfiles_dir())


@app.command("pipe-all")
def pipe_all(
    args: Annotated[list[str], typer.Argument(help="terraform apply arguments")] = [],
) -> None:
    """Run every stage in dependency order, then commit and format once."""
    stages = registry()["order"]
    run(["git", "-C", str(secrets_dir()), "pull", "--ff-only"])
    for stage in stages:
        print(f"== stage: {stage}")
        apply_stage(stage, args)
    commit_outputs(f"Terraform {'+'.join(stages)} apply")
    run(["nix", "fmt"], cwd=dotfiles_dir())
