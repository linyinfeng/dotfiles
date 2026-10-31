from pathlib import Path

import pytest
import typer

from maintain import secrets
from maintain.common import secrets_dir, secrets_extract_dir


def test_infrastructure_sops_files_includes_both_stages_and_legacy_files(tmp_path):
    expected = [
        tmp_path / name
        for name in [
            "predefined.yaml",
            "terraform-inputs.yaml",
            "terraform/outputs/pre-nixos.yaml",
            "terraform/outputs/post-nixos.yaml",
            "terraform/outputs/root-ca.yaml",
            "terraform/states/pre-nixos.tfstate",
            "terraform/states/post-nixos.tfstate",
            "terraform/states/root-ca.tfstate",
            "terraform-outputs.yaml",
            "terraform.tfstate",
            "terraform.plan",
        ]
    ]
    for path in expected:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("")
    for name in ["README.md", ".sops.yaml", "terraform.tfstate.backup", ".git/config"]:
        path = tmp_path / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("")
    (tmp_path / "terraform/outputs/not-a-file.yaml").mkdir()

    assert secrets.infrastructure_sops_files(tmp_path) == sorted(expected)


def test_update_keys_covers_both_repositories_with_dotfiles_config(
    tmp_path, monkeypatch
):
    dotfiles = tmp_path / "dotfiles"
    extracted = tmp_path / "custom-extracted-secrets"
    infrastructure = tmp_path / "custom-infrastructure-secrets"
    host = extracted / "terraform/hosts/host.yaml"
    state = infrastructure / "terraform/states/pre-nixos.tfstate"
    inputs = infrastructure / "terraform-inputs.yaml"
    expected = sorted([host, state, inputs])
    for path in expected:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("")
    monkeypatch.setenv("DOTFILES_DIR", str(dotfiles))
    monkeypatch.delenv("MAINTAIN_SOPS_CONFIG", raising=False)
    monkeypatch.setenv("SECRETS_DIR", str(infrastructure))
    monkeypatch.setenv("SECRETS_EXTRACT_DIR", str(extracted))
    calls = []
    monkeypatch.setattr(secrets, "run", lambda cmd: calls.append(cmd))

    secrets.update_keys()

    assert calls == [
        [
            "sops",
            "--config",
            str(dotfiles / ".sops.yaml"),
            "updatekeys",
            "--yes",
            str(path),
        ]
        for path in expected
    ]


def test_update_keys_fails_before_changes_if_infrastructure_is_missing(
    tmp_path, monkeypatch
):
    monkeypatch.setenv("DOTFILES_DIR", str(tmp_path))
    monkeypatch.setenv("SECRETS_DIR", str(tmp_path / "missing"))
    calls = []
    monkeypatch.setattr(secrets, "run", lambda cmd: calls.append(cmd))

    with pytest.raises(typer.BadParameter, match="secrets directory does not exist"):
        secrets.update_keys()
    assert calls == []


def test_env_path_absolutizes(tmp_path, monkeypatch):
    monkeypatch.setenv("SECRETS_DIR", "infrastructure-secrets")
    monkeypatch.chdir(tmp_path)

    assert secrets_dir() == tmp_path / "infrastructure-secrets"


def test_env_path_default_is_lazy(monkeypatch):
    monkeypatch.delenv("SECRETS_EXTRACT_DIR", raising=False)
    monkeypatch.setattr("maintain.common.repo_root", lambda: Path("/repo"))

    assert secrets_extract_dir() == Path("/repo/secrets")


def test_encrypted_outputs_falls_back_to_the_pre_split_layout(tmp_path, monkeypatch):
    monkeypatch.setenv("SECRETS_DIR", str(tmp_path))
    (tmp_path / "terraform-outputs.yaml").write_text("")

    assert secrets.encrypted_outputs("pre-nixos") == tmp_path / "terraform-outputs.yaml"


def test_encrypted_outputs_prefers_the_split_layout(tmp_path, monkeypatch):
    monkeypatch.setenv("SECRETS_DIR", str(tmp_path))
    (tmp_path / "terraform-outputs.yaml").write_text("")
    split = tmp_path / "terraform/outputs/pre-nixos.yaml"
    split.parent.mkdir(parents=True)
    split.write_text("")

    assert secrets.encrypted_outputs("pre-nixos") == split


def test_sops_config_uses_the_packaged_rules(monkeypatch):
    monkeypatch.setenv("MAINTAIN_SOPS_CONFIG", "/packaged/sops.yaml")

    assert secrets.sops_config() == Path("/packaged/sops.yaml")


def test_encrypt_uses_the_packaged_rules_for_new_files(tmp_path, monkeypatch):
    monkeypatch.setenv("MAINTAIN_SOPS_CONFIG", "/packaged/sops.yaml")
    calls = []
    monkeypatch.setattr(secrets, "run", lambda cmd, **kwargs: calls.append(cmd))

    secrets.encrypt_to_file(
        tmp_path / "plain", tmp_path / "root-ca.tfstate", "json", []
    )

    assert calls[0][:3] == ["sops", "--config", "/packaged/sops.yaml"]


def test_decrypt_keeps_plaintext_private(tmp_path, monkeypatch):
    target = tmp_path / "terraform.tfstate"
    target.write_text("old")
    target.chmod(0o644)

    def fake_decrypt(cmd, stdout):
        stdout.write("synthetic plaintext")

    monkeypatch.setattr(secrets, "run", fake_decrypt)

    secrets.decrypt(tmp_path / "encrypted", target, "json")

    assert target.read_text() == "synthetic plaintext"
    assert target.stat().st_mode & 0o777 == 0o600
