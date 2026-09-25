from pathlib import Path

from maintain import secrets


def test_sops_files(tmp_path):
    (tmp_path / "secrets/nixos").mkdir(parents=True)
    (tmp_path / "secrets/nixos/host.yaml").write_text("")
    (tmp_path / "secrets/README.md").write_text("")

    assert [p.name for p in secrets.sops_files(tmp_path)] == ["host.yaml"]


def test_env_path_absolutizes(tmp_path, monkeypatch):
    monkeypatch.setenv("SECRETS_DIR", "infrastructure-secrets")
    monkeypatch.chdir(tmp_path)

    assert secrets.secrets_dir() == tmp_path / "infrastructure-secrets"


def test_env_path_default_is_lazy(monkeypatch):
    monkeypatch.delenv("SECRETS_EXTRACT_DIR", raising=False)
    monkeypatch.setattr(secrets, "repo_root", lambda: Path("/repo"))

    assert secrets.extract_dir() == Path("/repo/secrets")
