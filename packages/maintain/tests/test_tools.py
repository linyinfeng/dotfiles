from pathlib import Path

import pytest
import typer

from maintain import tools


def test_insert_before_puts_the_block_above_the_anchor(tmp_path):
    target = tmp_path / "hosts.nix"
    target.write_text("start\n# PLACEHOLDER new host\nend\n")

    tools.insert_before(target, "# PLACEHOLDER new host", "inserted\n")

    assert target.read_text() == "start\ninserted\n# PLACEHOLDER new host\nend\n"


def test_insert_before_fails_on_a_missing_anchor(tmp_path):
    target = tmp_path / "hosts.nix"
    target.write_text("start\nend\n")

    with pytest.raises(typer.Exit) as excinfo:
        tools.insert_before(target, "# PLACEHOLDER new host", "inserted\n")

    assert excinfo.value.exit_code == 2
    assert target.read_text() == "start\nend\n"


def test_host_template_keeps_the_placeholders():
    rendered = tools.HOST_TEMPLATE.replace("STATE_VERSION", "26.05")

    assert 'system.stateVersion = "26.05";' in rendered
    assert "# PLACEHOLDER" in rendered


def test_new_host_keeps_identity_out_of_notices(tmp_path, monkeypatch, capsys):
    monkeypatch.setenv("DOTFILES_DIR", str(tmp_path))
    for name in [
        "flake/hosts.nix",
        "terraform/stages/pre-nixos/hosts.tf",
        "devshell/sops-yaml.nix",
    ]:
        path = tmp_path / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("# PLACEHOLDER new host\n")
    monkeypatch.setattr(tools, "captured", lambda *a, **kw: "26.05")
    monkeypatch.setattr(tools, "run", lambda *a, **kw: None)

    tools.new_host("test-host", "x86_64-linux")

    key = tmp_path / ".data/keys/test-host/age.key"
    assert key.stat().st_mode & 0o777 == 0o600
    notice = (tmp_path / "prepare-host-notice-test-host").read_text()
    assert str(key) in notice
    assert "AGE-SECRET-KEY-" not in notice
    output = capsys.readouterr()
    assert "AGE-SECRET-KEY-" not in output.out + output.err
    assert 'key = "age1' in (tmp_path / "devshell/sops-yaml.nix").read_text()


def test_new_host_refuses_existing_configuration(tmp_path, monkeypatch):
    monkeypatch.setenv("DOTFILES_DIR", str(tmp_path))
    host = tmp_path / "nixos/hosts/ostrich"
    host.mkdir(parents=True)
    config = host / "default.nix"
    config.write_text("keep existing configuration")
    with pytest.raises(typer.BadParameter, match="host already exists"):
        tools.new_host("ostrich", "x86_64-linux")
    assert config.read_text() == "keep existing configuration"
    assert not (tmp_path / ".data").exists()
