import subprocess
from types import SimpleNamespace

import pytest
from typer.testing import CliRunner

from maintain import nixos
from maintain.cli import app


@pytest.fixture
def setup_image(tmp_path, monkeypatch):
    monkeypatch.setenv("DOTFILES_DIR", str(tmp_path))
    key = tmp_path / ".data/keys/test-host/age.key"
    key.parent.mkdir(parents=True)
    key.write_text("AGE-SECRET-KEY-TEST")
    key.chmod(0o600)
    calls = []
    settings = {"key_target": "/persist/var/lib/sops-nix/key", "cores": "4"}
    monkeypatch.delenv("NIX_BUILD_CORES", raising=False)
    monkeypatch.setattr(nixos.os, "cpu_count", lambda: 4)

    def query(command, **kwargs):
        assert command == [
            "nix",
            "eval",
            "--raw",
            f"{tmp_path}#nixosConfigurations.test-host.config.sops.age.keyFile",
        ]
        calls.append("query")
        return SimpleNamespace(stdout=settings["key_target"])

    def build(reference, output):
        assert (
            reference
            == f"{tmp_path}#nixosConfigurations.test-host.config.system.build.diskoImagesScript"
        )
        assert "AGE-SECRET-KEY-" not in reference
        output.write_text("runtime builder")
        calls.append("build")

    def generate(command, *, cwd, umask, env):
        assert command[1:] == ["--post-format-files", str(key), settings["key_target"]]
        assert cwd.stat().st_mode & 0o777 == 0o700
        assert umask == 0o077
        assert env["NIX_BUILD_CORES"] == settings["cores"]
        (cwd / "main.qcow2").write_bytes(b"generated disk")
        (cwd / "main.qcow2").chmod(0o644)
        calls.append("generate")

    monkeypatch.setattr(nixos.subprocess, "run", query)
    monkeypatch.setattr(nixos, "nix_build", build)
    monkeypatch.setattr(nixos, "run", generate)
    return key, calls, settings


@pytest.mark.parametrize(
    "key_target", ["/persist/var/lib/sops-nix/key", "/var/lib/sops-nix/key"]
)
@pytest.mark.parametrize("custom_output", [False, True])
def test_image_injects_standard_identity_at_configured_destination(
    tmp_path, setup_image, key_target, custom_output
):
    _, calls, settings = setup_image
    settings["key_target"] = key_target
    target = tmp_path / (
        "output with spaces" if custom_output else ".data/nixos/test-host-image"
    )
    args = ["nixos", "image", "test-host"]
    if custom_output:
        args += ["--output", str(target)]
    result = CliRunner().invoke(app, args)
    assert result.exit_code == 0, result.output
    assert calls == ["query", "build", "generate"]
    assert target.stat().st_mode & 0o777 == 0o700
    assert (target / "main.qcow2").stat().st_mode & 0o777 == 0o600
    assert "AGE-SECRET-KEY-" not in result.output
    assert "image ready:" in result.output
    assert not list(target.parent.glob(".nixos.*"))


@pytest.mark.parametrize(
    "problem", ["missing", "permissions", "existing_output", "symlink_output"]
)
def test_image_rejects_invalid_inputs_before_nix(tmp_path, setup_image, problem):
    key, calls, _ = setup_image
    target = tmp_path / ".data/nixos/test-host-image"
    if problem == "missing":
        key.unlink()
    elif problem == "permissions":
        key.chmod(0o644)
    else:
        target.parent.mkdir(parents=True)
        if problem == "existing_output":
            target.mkdir()
            (target / "keep").write_text("keep")
        else:
            target.symlink_to(tmp_path / "missing-image")
    result = CliRunner().invoke(app, ["nixos", "image", "test-host"])
    assert result.exit_code != 0
    assert calls == []
    if problem == "existing_output":
        assert (target / "keep").read_text() == "keep"
    elif problem == "symlink_output":
        assert target.is_symlink()
        assert not target.exists()


@pytest.mark.parametrize("destination", ["relative/key", "/", "/persist/../key"])
def test_image_rejects_invalid_key_destination(tmp_path, setup_image, destination):
    _, calls, settings = setup_image
    settings["key_target"] = destination
    result = CliRunner().invoke(app, ["nixos", "image", "test-host"])
    assert result.exit_code != 0
    assert "absolute file path" in result.output
    assert calls == ["query"]
    assert not (tmp_path / ".data/nixos").exists()


def test_failed_runtime_build_keeps_output_private(tmp_path, monkeypatch, setup_image):
    def fail(command, *, cwd, umask, env):
        assert cwd.stat().st_mode & 0o777 == 0o700
        assert umask == 0o077
        raise subprocess.CalledProcessError(1, command)

    monkeypatch.setattr(nixos, "run", fail)
    result = CliRunner().invoke(app, ["nixos", "image", "test-host"])
    assert result.exit_code != 0
    assert "image ready:" not in result.output
    assert "AGE-SECRET-KEY-" not in result.output
    assert (tmp_path / ".data/nixos/test-host-image").stat().st_mode & 0o777 == 0o700


def test_image_preserves_explicit_build_cores(monkeypatch, setup_image):
    _, _, settings = setup_image
    monkeypatch.setenv("NIX_BUILD_CORES", "2")
    settings["cores"] = "2"
    result = CliRunner().invoke(app, ["nixos", "image", "test-host"])
    assert result.exit_code == 0, result.output
