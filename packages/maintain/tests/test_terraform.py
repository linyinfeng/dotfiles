import json

import pytest
import typer

from maintain import terraform

REGISTRY = {
    "order": ["pre-nixos", "post-nixos"],
    "stages": {
        "pre-nixos": {
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
    assert "TF_VAR_pre_nixos_outputs_path" not in env


def test_stage_env_keeps_an_explicit_override(monkeypatch):
    monkeypatch.setenv("SECRETS_DIR", "/secrets")
    monkeypatch.setenv("TF_VAR_terraform_input_path", "/elsewhere/inputs.yaml")

    env = terraform.stage_env("pre-nixos")

    assert env["TF_VAR_terraform_input_path"] == "/elsewhere/inputs.yaml"
