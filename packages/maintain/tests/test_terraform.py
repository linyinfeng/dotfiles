import json
import subprocess
from pathlib import Path

import pytest
import typer
from typer.testing import CliRunner

from maintain import terraform


def git(repo, *args):
    return subprocess.run(
        ["git", "-C", str(repo), *args], check=True, capture_output=True, text=True
    ).stdout.strip()


@pytest.fixture
def terraform_checkout(tmp_path, monkeypatch):
    monkeypatch.setenv("GIT_CONFIG_NOSYSTEM", "1")
    monkeypatch.setenv("GIT_CONFIG_GLOBAL", "/dev/null")
    remote = tmp_path / "remote.git"
    repo = tmp_path / "private"
    repo.mkdir()
    git(tmp_path, "init", "--bare", "--initial-branch=main", str(remote))
    git(repo, "init", "--initial-branch=main")
    git(repo, "config", "user.name", "Test")
    git(repo, "config", "user.email", "test@example.invalid")
    (repo / "README").write_text("fixture")
    git(repo, "add", "README")
    git(repo, "commit", "-m", "Initial")
    git(repo, "remote", "add", "origin", str(remote))
    git(repo, "push", "-u", "origin", "main")
    monkeypatch.delenv("CI", raising=False)
    monkeypatch.delenv("GITHUB_ACTIONS", raising=False)
    monkeypatch.setenv("TERRAFORM_DIR", str(tmp_path / "terraform"))
    monkeypatch.setenv("SECRETS_DIR", str(repo))
    monkeypatch.setenv("DOTFILES_DIR", str(tmp_path))
    for stage in REGISTRY["stages"]:
        (tmp_path / "terraform/stages" / stage).mkdir(parents=True)
    return repo, remote


REGISTRY = {
    "order": ["pre-nixos", "post-nixos"],
    "manual": ["intermediate-ca", "root-ca"],
    "stages": {
        "intermediate-ca": {},
        "root-ca": {},
        "pre-nixos": {
            "root_ca_outputs_path": "${SECRETS_DIR}/terraform/outputs/root-ca.yaml",
            "terraform_input_path": "${SECRETS_DIR}/terraform-inputs.yaml",
            "predefined_secrets_path": "${SECRETS_DIR}/predefined.yaml",
        },
        "post-nixos": {
            "terraform_input_path": "${SECRETS_DIR}/terraform-inputs.yaml",
            "pre_nixos_outputs_path": "${SECRETS_DIR}/terraform/outputs/pre-nixos.yaml",
        },
    },
}


@pytest.fixture(autouse=True)
def fake_registry(tmp_path, monkeypatch):
    path = tmp_path / "terraform-stages.json"
    path.write_text(json.dumps(REGISTRY))
    monkeypatch.setenv("MAINTAIN_STAGE_REGISTRY", str(path))
    terraform.reset_registry()


def test_leading_stage_argument_wins(monkeypatch):
    monkeypatch.setenv("TERRAFORM_STAGE", "post-nixos")

    assert terraform.stage_from(["pre-nixos", "plan"]) == ("pre-nixos", ["plan"])


def test_stage_falls_back_to_the_environment(monkeypatch):
    monkeypatch.setenv("TERRAFORM_STAGE", "post-nixos")

    assert terraform.stage_from(["plan", "-refresh=false"]) == (
        "post-nixos",
        ["plan", "-refresh=false"],
    )


def test_missing_stage_is_an_error(monkeypatch):
    monkeypatch.delenv("TERRAFORM_STAGE", raising=False)

    with pytest.raises(typer.Exit) as excinfo:
        terraform.stage_from([])

    assert excinfo.value.exit_code == 2


def test_unknown_stage_is_an_error(monkeypatch):
    monkeypatch.setenv("TERRAFORM_STAGE", "nope")

    with pytest.raises(typer.Exit) as excinfo:
        terraform.stage_from([])

    assert excinfo.value.exit_code == 2


def test_stage_env_drops_the_other_stages_variables(monkeypatch):
    monkeypatch.setenv("SECRETS_DIR", "/secrets")
    monkeypatch.setenv("TF_VAR_pre_nixos_outputs_path", "leftover")

    env = terraform.stage_env("pre-nixos")

    assert env["TF_VAR_terraform_input_path"] == "/secrets/terraform-inputs.yaml"
    assert (
        env["TF_VAR_root_ca_outputs_path"] == "/secrets/terraform/outputs/root-ca.yaml"
    )
    assert "TF_VAR_pre_nixos_outputs_path" not in env


def test_stage_env_absolutizes_the_secrets_dir(monkeypatch, tmp_path):
    # CI passes SECRETS_DIR relative to its workspace root, but terraform runs with -chdir
    monkeypatch.setenv("SECRETS_DIR", "infrastructure-secrets")
    monkeypatch.chdir(tmp_path)

    env = terraform.stage_env("pre-nixos")

    assert env["TF_VAR_terraform_input_path"] == str(
        tmp_path / "infrastructure-secrets/terraform-inputs.yaml"
    )


def test_stage_env_keeps_an_explicit_override(monkeypatch):
    monkeypatch.setenv("SECRETS_DIR", "/secrets")
    monkeypatch.setenv("TF_VAR_terraform_input_path", "/elsewhere/inputs.yaml")

    env = terraform.stage_env("pre-nixos")

    assert env["TF_VAR_terraform_input_path"] == "/elsewhere/inputs.yaml"


@pytest.mark.parametrize("stage", ["intermediate-ca", "root-ca"])
def test_manual_ca_is_explicitly_available_locally(monkeypatch, stage):
    monkeypatch.delenv("CI", raising=False)
    monkeypatch.delenv("GITHUB_ACTIONS", raising=False)
    monkeypatch.setenv("TERRAFORM_STAGE", "pre-nixos")

    assert terraform.stage_from([stage, "plan"]) == (stage, ["plan"])


@pytest.mark.parametrize("name", ["CI", "GITHUB_ACTIONS"])
@pytest.mark.parametrize("stage", ["intermediate-ca", "root-ca"])
def test_manual_ca_refuses_ci_before_running_commands(monkeypatch, name, stage):
    monkeypatch.setenv(name, "true")
    calls = []
    monkeypatch.setattr(terraform, "run", lambda *args, **kwargs: calls.append(args))

    with pytest.raises(typer.Exit) as excinfo:
        terraform.init([stage])

    assert excinfo.value.exit_code == 2
    assert calls == []


@pytest.mark.parametrize("stage", [None, "root-ca", "intermediate-ca"])
def test_update_locks_in_ci_without_secrets(tmp_path, monkeypatch, stage):
    monkeypatch.setenv("CI", "true")
    monkeypatch.setenv("GITHUB_ACTIONS", "true")
    monkeypatch.setenv("TERRAFORM_STAGE", "pre-nixos")
    monkeypatch.setenv("TERRAFORM_DIR", str(tmp_path / "terraform"))
    monkeypatch.setenv("SECRETS_DIR", str(tmp_path / "does-not-exist"))
    for name in REGISTRY["stages"]:
        root = tmp_path / "terraform/stages" / name
        root.mkdir(parents=True)
        (root / "terraform.tfstate").write_text("must not be read")
        (root / ".terraform-data").mkdir()
        (root / ".terraform-data/terraform.tfstate").write_text("backend metadata")
    calls = []
    data_dirs = []

    def fake_init(args, env):
        data = Path(env["TF_DATA_DIR"])
        root = Path(args[1].removeprefix("-chdir="))
        assert data.is_dir() and not list(data.iterdir())
        assert not (root / "terraform.tfstate").exists()
        assert not (root / ".terraform-data").exists()
        assert args[2:] == ["init", "-backend=false", "-input=false", "-upgrade"]
        (root / ".terraform.lock.hcl").write_text("updated provider lock")
        calls.append(root.name)
        data_dirs.append(data)

    monkeypatch.setattr(terraform, "run", fake_init)
    terraform.update_locks(stage)

    assert calls == ([stage] if stage else sorted(REGISTRY["stages"]))
    for name in calls:
        root = tmp_path / "terraform/stages" / name
        assert (root / ".terraform.lock.hcl").read_text() == "updated provider lock"
        assert (root / "terraform.tfstate").read_text() == "must not be read"
    assert all(not path.exists() for path in data_dirs)
    assert not (tmp_path / "does-not-exist").exists()


def test_update_locks_rejects_unknown_stage_before_commands(monkeypatch):
    calls = []
    monkeypatch.setattr(terraform, "run", lambda *args, **kwargs: calls.append(args))
    with pytest.raises(typer.BadParameter, match="unknown terraform stage"):
        terraform.update_locks("unknown")
    assert calls == []


def test_update_locks_stops_on_failure_and_removes_temporary_data(
    tmp_path, monkeypatch
):
    monkeypatch.setenv("TERRAFORM_DIR", str(tmp_path))
    for name in REGISTRY["stages"]:
        (tmp_path / "stages" / name).mkdir(parents=True)
    data_dirs = []

    def fail_init(args, env):
        data_dirs.append(Path(env["TF_DATA_DIR"]))
        raise subprocess.CalledProcessError(1, args)

    monkeypatch.setattr(terraform, "run", fail_init)
    with pytest.raises(subprocess.CalledProcessError):
        terraform.update_locks()
    assert len(data_dirs) == 1
    assert not data_dirs[0].exists()


@pytest.mark.parametrize("include_manual", [False, True])
def test_pipe_all_stage_order(terraform_checkout, monkeypatch, include_manual):
    calls = []
    real_run = terraform.run
    monkeypatch.setattr(
        terraform,
        "run",
        lambda args, **kwargs: (
            None
            if args[0] == "nix"
            else real_run(args, **(kwargs | {"stdout": subprocess.PIPE}))
        ),
    )
    monkeypatch.setattr(
        terraform, "apply_stage", lambda stage, args: calls.append((stage, args))
    )
    monkeypatch.setattr(
        terraform.secrets,
        "extract_sources",
        lambda source: calls.append(("extract", source)),
    )

    result = CliRunner().invoke(
        terraform.app,
        [
            "pipe-all",
            *(["--include-manual"] if include_manual else []),
            "--",
            "-parallelism=2",
        ],
    )

    assert result.exit_code == 0, result.output
    stages = (["intermediate-ca", "root-ca"] if include_manual else []) + [
        "pre-nixos",
        "post-nixos",
    ]
    assert calls == [(stage, ["-parallelism=2"]) for stage in stages] + [
        ("extract", "terraform")
    ]


@pytest.mark.parametrize("name", ["CI", "GITHUB_ACTIONS"])
def test_pipe_all_include_manual_refuses_ci_before_commands(monkeypatch, name):
    monkeypatch.setenv(name, "true")
    calls = []
    monkeypatch.setattr(terraform, "run", lambda *args, **kwargs: calls.append(args))
    monkeypatch.setattr(terraform, "apply_stage", lambda *args: calls.append(args))

    result = CliRunner().invoke(terraform.app, ["pipe-all", "--include-manual"])

    assert result.exit_code == 2, result.output
    assert "cannot run in CI" in result.output
    assert calls == []


def test_bootstrap_creates_empty_state_and_refuses_a_second_run(
    terraform_checkout, monkeypatch
):
    repo, remote = terraform_checkout
    calls = []

    def fake_encrypt(plain, encrypted, type, formatter):
        state = json.loads(plain.read_text())
        calls.append(state)
        encrypted.write_text("synthetic encrypted state")

    monkeypatch.setattr(terraform.secrets, "encrypt_to_file", fake_encrypt)

    terraform.bootstrap(["root-ca"])
    assert calls[0]["version"] == 4
    assert calls[0]["resources"] == []
    assert calls[0]["lineage"]
    assert (repo / "terraform/states/root-ca.tfstate").exists()
    assert (
        git(remote, "show", "main:terraform/states/root-ca.tfstate")
        == "synthetic encrypted state"
    )
    first_commit = git(remote, "rev-parse", "main")

    with pytest.raises(typer.BadParameter, match="state already exists"):
        terraform.bootstrap(["root-ca"])
    assert len(calls) == 1
    assert git(remote, "rev-parse", "main") == first_commit


def test_bootstrap_refuses_routine_stages():
    with pytest.raises(typer.BadParameter, match="manual stage"):
        terraform.bootstrap(["pre-nixos"])


def write_stage_state(repo, stage, content):
    state = repo / f"terraform/states/{stage}.tfstate"
    state.parent.mkdir(parents=True, exist_ok=True)
    state.write_text(content)
    return state


def test_bootstrap_checks_for_existing_state_after_pull(terraform_checkout, tmp_path):
    repo, remote = terraform_checkout
    other = tmp_path / "other"
    git(tmp_path, "clone", str(remote), str(other))
    git(other, "config", "user.name", "Other")
    git(other, "config", "user.email", "other@example.invalid")
    write_stage_state(other, "root-ca", "remote encrypted state")
    git(other, "add", ".")
    git(other, "commit", "-m", "Bootstrap elsewhere")
    git(other, "push")

    with pytest.raises(typer.BadParameter, match="state already exists"):
        terraform.bootstrap(["root-ca"])

    assert (
        repo / "terraform/states/root-ca.tfstate"
    ).read_text() == "remote encrypted state"


def test_transaction_commits_only_its_stage_and_preserves_other_staged_changes(
    terraform_checkout,
):
    repo, remote = terraform_checkout
    unrelated = repo / "other-secret.yaml"
    unrelated.write_text("unrelated")
    git(repo, "add", unrelated.name)
    before = git(remote, "rev-parse", "main")

    with terraform.state_transaction(["root-ca"], "Root bootstrap"):
        write_stage_state(repo, "root-ca", "encrypted root")

    assert (
        git(remote, "diff", "--name-only", before, "main")
        == "terraform/states/root-ca.tfstate"
    )
    assert git(repo, "diff", "--cached", "--name-only") == unrelated.name


@pytest.mark.parametrize("push_fails", [False, True])
def test_failed_apply_encrypts_and_publishes_partial_state(
    terraform_checkout, tmp_path, monkeypatch, push_fails
):
    repo, remote = terraform_checkout
    state = write_stage_state(repo, "pre-nixos", "previous encrypted state")
    git(repo, "add", ".")
    git(repo, "commit", "-m", "Initial state")
    git(repo, "push")
    if push_fails:
        git(
            repo, "remote", "set-url", "--push", "origin", str(tmp_path / "missing.git")
        )
    plain = tmp_path / "terraform/stages/pre-nixos/terraform.tfstate"
    monkeypatch.setattr(
        terraform.secrets,
        "decrypt",
        lambda source, target, type: target.write_text('{"serial":0}'),
    )
    monkeypatch.setattr(
        terraform.secrets,
        "encrypt_to_file",
        lambda source, target, type, formatter: target.write_text(
            "encrypted:" + source.read_text()
        ),
    )
    real_subprocess_run = subprocess.run

    def partial_apply(args, **kwargs):
        if args[0] == "terraform":
            plain.write_text('{"serial":1}')
            return subprocess.CompletedProcess(args, 17)
        return real_subprocess_run(args, **kwargs)

    monkeypatch.setattr(terraform.subprocess, "run", partial_apply)
    with pytest.raises(typer.Exit) as excinfo:
        terraform.run_terraform(["pre-nixos", "apply"])

    assert excinfo.value.exit_code == 17
    assert state.read_text() == 'encrypted:{"serial":1}'
    assert not plain.exists()
    assert git(repo, "status", "--porcelain") == ""
    assert (
        git(repo, "show", "HEAD:terraform/states/pre-nixos.tfstate")
        == state.read_text()
    )
    if push_fails:
        assert (
            git(remote, "show", "main:terraform/states/pre-nixos.tfstate")
            == "previous encrypted state"
        )
    else:
        assert (
            git(remote, "show", "main:terraform/states/pre-nixos.tfstate")
            == state.read_text()
        )


def test_push_failure_preserves_commit_and_next_transaction_retries(
    terraform_checkout, tmp_path
):
    repo, remote = terraform_checkout
    before = git(remote, "rev-parse", "main")
    git(repo, "remote", "set-url", "--push", "origin", str(tmp_path / "missing.git"))

    with pytest.raises(subprocess.CalledProcessError):
        with terraform.state_transaction(["root-ca"], "Create root state"):
            state = write_stage_state(repo, "root-ca", "encrypted state")

    pending = git(repo, "rev-parse", "HEAD")
    assert pending != before
    assert git(remote, "rev-parse", "main") == before
    assert state.read_text() == "encrypted state"
    git(repo, "remote", "set-url", "--push", "origin", str(remote))
    with terraform.state_transaction(["root-ca"], "No further changes"):
        pass
    assert git(remote, "rev-parse", "main") == pending


def test_no_changes_do_not_create_commit(terraform_checkout):
    repo, remote = terraform_checkout
    before = git(remote, "rev-parse", "main")
    with terraform.state_transaction(["root-ca"], "No changes"):
        pass
    assert git(repo, "rev-parse", "HEAD") == before
    assert git(remote, "rev-parse", "main") == before


def test_dirty_stage_files_block_execution(terraform_checkout):
    repo, _ = terraform_checkout
    write_stage_state(repo, "root-ca", "pending encrypted state")
    with pytest.raises(typer.Exit) as excinfo:
        with terraform.state_transaction(["root-ca"], "Should not run"):
            pytest.fail("must not execute with uncommitted state")
    assert excinfo.value.exit_code == 2


def test_pull_failure_blocks_execution(terraform_checkout, monkeypatch):
    repo, _ = terraform_checkout
    git(repo, "remote", "set-url", "origin", str(repo / "missing.git"))
    with pytest.raises(subprocess.CalledProcessError):
        with terraform.state_transaction(["root-ca"], "Should not run"):
            pytest.fail("must not execute after a failed pull")


def test_pipe_all_publishes_completed_stages_when_later_stage_fails(
    terraform_checkout, monkeypatch
):
    repo, remote = terraform_checkout
    extractions = []
    monkeypatch.setattr(terraform.secrets, "extract_sources", extractions.append)

    def apply(stage, args):
        write_stage_state(repo, stage, f"encrypted {stage}")
        if stage == "post-nixos":
            raise typer.Exit(23)

    monkeypatch.setattr(terraform, "apply_stage", apply)
    with pytest.raises(typer.Exit) as excinfo:
        terraform.pipe_all([])
    assert excinfo.value.exit_code == 23
    assert extractions == []
    for stage in ("pre-nixos", "post-nixos"):
        assert (
            git(remote, "show", f"main:terraform/states/{stage}.tfstate")
            == f"encrypted {stage}"
        )


def test_git_sync_keeps_stdout_available_for_terraform_output(
    terraform_checkout, monkeypatch, capfd
):
    monkeypatch.setattr(
        terraform, "terraform_run", lambda *args: print("PUBLIC CERTIFICATE")
    )
    terraform.run_terraform(["root-ca", "output", "-raw", "root_ca_cert_pem"])
    assert capfd.readouterr().out == "PUBLIC CERTIFICATE\n"


@pytest.mark.parametrize("command", ["apply-stage", "pipe", "update-outputs"])
@pytest.mark.parametrize("stage", ["root-ca", "pre-nixos"])
def test_public_commands_share_state_sync(
    terraform_checkout, monkeypatch, command, stage
):
    repo, remote = terraform_checkout
    extractions = []
    monkeypatch.setattr(terraform.secrets, "extract_sources", extractions.append)
    monkeypatch.setattr(
        terraform,
        "apply_stage",
        lambda stage, args: write_stage_state(repo, stage, "encrypted apply"),
    )
    monkeypatch.setattr(
        terraform,
        "write_outputs",
        lambda stage, args: write_stage_state(repo, stage, "encrypted outputs"),
    )
    real_run = terraform.run
    monkeypatch.setattr(
        terraform,
        "run",
        lambda args, **kwargs: None if args[0] == "nix" else real_run(args, **kwargs),
    )
    commands = {
        "apply-stage": terraform.apply_stage_command,
        "pipe": terraform.pipe,
        "update-outputs": terraform.update_outputs,
    }
    commands[command]([stage])
    expected = "encrypted outputs" if command == "update-outputs" else "encrypted apply"
    assert git(remote, "show", f"main:terraform/states/{stage}.tfstate") == expected
    assert extractions == (
        ["terraform"] if stage == "pre-nixos" and command != "update-outputs" else []
    )


def test_local_lock_blocks_a_second_transaction(terraform_checkout):
    with terraform.state_lock():
        with pytest.raises(typer.Exit) as excinfo:
            with terraform.state_transaction(["root-ca"], "Should not run"):
                pytest.fail("must not overlap a local state operation")
        assert excinfo.value.exit_code == 2


@pytest.mark.parametrize("flag", ["-migrate-state", "-force-copy"])
def test_init_refuses_backend_migration_flags(flag):
    with pytest.raises(typer.BadParameter, match="migration"):
        terraform.init(["pre-nixos", flag])
