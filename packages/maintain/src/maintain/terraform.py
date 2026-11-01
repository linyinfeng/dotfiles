"""terraform pipelines: one encrypted state per stage, plus their outputs."""

import fcntl
import json
import os
import signal
import shutil
import string
import subprocess
import sys
import tempfile
import uuid
from contextlib import contextmanager
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

    check_manual_stage(stage)
    return stage, args[1:] if given else args


def check_manual_stage(stage: str) -> None:
    if stage in registry().get("manual", []) and any(
        os.environ.get(name, "").lower() not in ("", "0", "false")
        for name in ("CI", "GITHUB_ACTIONS")
    ):
        message(f"stage {stage} is local-only and cannot run in CI")
        raise typer.Exit(2)


def stage_root(stage: str) -> Path:
    check_manual_stage(stage)
    return stage_directory(stage)


def stage_directory(stage: str) -> Path:
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


def stage_files(stages: list[str]) -> list[str]:
    """Repository-relative files owned by these stages, including legacy state."""
    paths = [
        f"terraform/{kind}/{stage}.{suffix}"
        for stage in stages
        for kind, suffix in (("states", "tfstate"), ("outputs", "yaml"))
    ]
    if "pre-nixos" in stages:
        paths.extend(["terraform.tfstate", "terraform-outputs.yaml"])
    return paths


def changed_files(paths: list[str]) -> list[str]:
    result = subprocess.run(
        [
            "git",
            "-C",
            str(secrets_dir()),
            "status",
            "--porcelain=v1",
            "--no-renames",
            "-z",
            "--",
            *paths,
        ],
        check=True,
        capture_output=True,
    )
    return [os.fsdecode(entry[3:]) for entry in result.stdout.split(b"\0") if entry]


@contextmanager
def state_lock():
    """Serialize local invocations, including their decrypt/encrypt windows."""
    result = subprocess.run(
        ["git", "-C", str(secrets_dir()), "rev-parse", "--absolute-git-dir"],
        check=True,
        capture_output=True,
        text=True,
    )
    with (Path(result.stdout.strip()) / "maintain-terraform.lock").open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            message("another local Terraform command is using this secrets repository")
            raise typer.Exit(2)
        yield


def publish_state(paths: list[str], commit_message: str) -> None:
    repo = str(secrets_dir())
    changed = changed_files(paths)
    if changed:
        run(["git", "-C", repo, "add", "--all", "--", *changed], stdout=sys.stderr)
        run(
            [
                "git",
                "-C",
                repo,
                "commit",
                "--only",
                "--message",
                commit_message,
                "--",
                *changed,
            ],
            stdout=sys.stderr,
        )
    else:
        message("stage state and outputs are unchanged, nothing to commit")
    # Retry a previous unpushed commit even when this invocation changed no files.
    try:
        run(["git", "-C", repo, "push"], stdout=sys.stderr)
    except Exception:
        message(
            "push failed; encrypted state and local commits are preserved; retry git push before continuing"
        )
        raise


@contextmanager
def state_transaction(stages: list[str], commit_message: str):
    for stage in stages:
        stage_root(stage)
    paths = stage_files(stages)
    with state_lock():
        dirty = changed_files(paths)
        if dirty:
            message(
                "stage files have uncommitted changes; commit/push or recover them before continuing: "
                + ", ".join(dirty)
            )
            raise typer.Exit(2)
        run(["git", "-C", str(secrets_dir()), "pull", "--ff-only"], stdout=sys.stderr)
        try:
            yield
        except BaseException:
            # Partial applies still change state. Preserve the original failure even
            # if publishing that state also fails; neither failure should discard it.
            try:
                publish_state(paths, commit_message)
            except Exception as error:
                message(
                    f"also failed to publish state after the command failed: {error}"
                )
            raise
        else:
            publish_state(paths, commit_message)


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
    if any(root.glob("terraform.tfstate*")):
        message(
            "plaintext state already exists; recover it before running Terraform again"
        )
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
    if any(arg.split("=", 1)[0] in ("-migrate-state", "-force-copy") for arg in rest):
        raise typer.BadParameter("backend state migration is not supported by init")
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


@app.command("update-locks")
def update_locks(
    stage: Annotated[
        str | None, typer.Argument(help="one stage; omit to update every stage")
    ] = None,
) -> None:
    """Upgrade provider locks without initializing backends or decrypting state."""
    stages = registry()["stages"]
    if stage is not None and stage not in stages:
        raise typer.BadParameter(f"unknown terraform stage: {stage}")
    # Resolve all directories before changing any locks. This maintenance-only
    # path also permits manual stages in CI; execution commands keep their guard.
    roots = [stage_directory(name) for name in ([stage] if stage else sorted(stages))]
    for root in roots:
        message(f"updating provider lock for {root.name}...")
        # Even init -backend=false probes local state. Copy only configuration,
        # retaining relative module paths, and write back only the provider lock.
        with tempfile.TemporaryDirectory(prefix="terraform-locks.") as data:
            snapshot = Path(data) / "terraform"
            shutil.copytree(
                terraform_dir(),
                snapshot,
                ignore=lambda directory, names: [
                    name
                    for name in names
                    if name in (".terraform", ".terraform-data", ".git")
                    or not (
                        (Path(directory) / name).is_dir()
                        or name.endswith((".tf", ".tf.json"))
                        or name == ".terraform.lock.hcl"
                    )
                ],
            )
            workdir = snapshot / root.relative_to(terraform_dir().resolve())
            init_data = Path(data) / "data"
            init_data.mkdir()
            run(
                [
                    "terraform",
                    f"-chdir={workdir}",
                    "init",
                    "-backend=false",
                    "-input=false",
                    "-upgrade",
                ],
                env=os.environ | {"TF_DATA_DIR": str(init_data)},
            )
            lock = workdir / ".terraform.lock.hcl"
            if lock.exists():
                shutil.copy2(lock, root / lock.name)


@app.command("bootstrap")
def bootstrap(
    args: Annotated[list[str], typer.Argument(help="manual stage to initialize")] = [],
) -> None:
    """Create an encrypted empty state once, only for an explicitly selected manual stage."""
    stage, rest = stage_from(args)
    if stage not in registry().get("manual", []) or rest:
        raise typer.BadParameter("bootstrap requires exactly one manual stage")
    with state_transaction([stage], f"Terraform {stage} bootstrap"):
        root = stage_root(stage)
        encrypted = encrypted_state(stage)
        if encrypted.exists() or any(root.glob("terraform.tfstate*")):
            raise typer.BadParameter(
                f"state already exists for {stage}; refusing to overwrite it"
            )
        encrypted.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="encrypt.") as tmp:
            plain = Path(tmp) / "empty-state.json"
            plain.write_text(
                json.dumps(
                    {
                        "version": 4,
                        "serial": 0,
                        "lineage": str(uuid.uuid4()),
                        "outputs": {},
                        "resources": [],
                    }
                )
            )
            secrets.encrypt_to_file(plain, encrypted, "json", ["yq", "--prettyPrint"])
    message(f"initialized encrypted state for {stage}")


@app.command("run")
def run_terraform(
    args: Annotated[
        list[str], typer.Argument(help="<stage> and terraform arguments")
    ] = [],
) -> None:
    """Run any terraform subcommand in a stage, its state handled automatically."""
    stage, rest = stage_from(args)
    with state_transaction([stage], f"Terraform {stage} run"):
        terraform_run(stage, rest)


@app.command("update-outputs")
def update_outputs(
    args: Annotated[
        list[str], typer.Argument(help="<stage> and terraform output arguments")
    ] = [],
) -> None:
    """Store the stage outputs encrypted in the secrets repository."""
    stage, rest = stage_from(args)
    with state_transaction([stage], f"Terraform {stage} update outputs"):
        write_outputs(stage, rest)


def write_outputs(stage: str, args: list[str]) -> None:
    with tempfile.TemporaryDirectory(prefix="encrypt.") as tmp:
        plain_output = Path(tmp) / "terraform-outputs.plain.yaml"
        with plain_output.open("w") as out:
            terraform_run(stage, ["output", "--json", *args], stdout=out)
        outputs = secrets_dir() / f"terraform/outputs/{stage}.yaml"
        outputs.parent.mkdir(parents=True, exist_ok=True)
        secrets.encrypt_to_file(plain_output, outputs, "yaml", ["yq", "--prettyPrint"])


@app.command("extract-data")
def extract_data() -> None:
    """Render lib/data/data.json from pre-nixos outputs and format the repository."""
    write_data()
    run(["nix", "fmt"], cwd=dotfiles_dir())


def write_data() -> None:
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
    """Recover pending Terraform state/output changes and push local commits."""
    with state_lock():
        publish_state(stage_files(list(registry()["stages"])), message_)


def apply_stage(stage: str, args: list[str]) -> None:
    """init, apply, refresh the outputs, and feed the NixOS inputs from pre-nixos."""
    init([stage])
    terraform_run(stage, ["apply", *args])
    write_outputs(stage, [])
    if stage == "pre-nixos":
        write_data()
        secrets.extract_sources("terraform")


@app.command("apply-stage")
def apply_stage_command(
    args: Annotated[
        list[str], typer.Argument(help="<stage> and terraform apply arguments")
    ] = [],
) -> None:
    """Initialize, apply and publish one stage."""
    stage, rest = stage_from(args)
    with state_transaction([stage], f"Terraform {stage} apply"):
        apply_stage(stage, rest)


@app.command("pipe")
def pipe(
    args: Annotated[
        list[str], typer.Argument(help="<stage> and terraform apply arguments")
    ] = [],
) -> None:
    """Apply one stage and, when it succeeded, commit its outputs and format the repository."""
    stage, rest = stage_from(args)
    with state_transaction([stage], f"Terraform {stage} apply"):
        apply_stage(stage, rest)
    run(["nix", "fmt"], cwd=dotfiles_dir())


@app.command("pipe-all")
def pipe_all(
    args: Annotated[list[str], typer.Argument(help="terraform apply arguments")] = [],
    include_manual: Annotated[
        bool,
        typer.Option(
            "--include-manual",
            help="Include local-only manual stages before routine stages",
        ),
    ] = False,
) -> None:
    """Run stages in dependency order, optionally including manual stages."""
    stages = registry()["order"]
    if include_manual:
        stages = registry().get("manual", []) + stages
    with state_transaction(stages, f"Terraform {'+'.join(stages)} apply"):
        for stage in stages:
            print(f"== stage: {stage}")
            apply_stage(stage, args)
    run(["nix", "fmt"], cwd=dotfiles_dir())
