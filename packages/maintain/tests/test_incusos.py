import json
import tarfile

import pytest
from typer.testing import CliRunner

from maintain import incusos
from maintain.cli import app


@pytest.mark.parametrize("arch", ["x86_64-linux", "aarch64-linux"])
def test_image_seeds_ca_without_forcing_install(tmp_path, monkeypatch, arch):
    monkeypatch.setattr(incusos, "client_ca", lambda: "PUBLIC CLIENT CA")
    output = tmp_path / "install.img"

    def flasher(command, *, cwd, env):
        assert env["INCUSOS_IMAGE_ARCHITECTURE"] == arch.removesuffix("-linux")
        seed = command[command.index("--seed") + 1]
        with tarfile.open(seed) as archive:
            install = json.load(archive.extractfile("install.json"))
            config = json.load(archive.extractfile("incus.json"))
            assert not install.get("force_install", False)
            assert "target" not in install
            assert (
                config["preseed"]["certificates"][0]["certificate"]
                == "PUBLIC CLIENT CA"
            )
            assert "network.json" not in archive.getnames()
        (cwd / "upstream.img").write_bytes(b"downloaded image with seed")

    monkeypatch.setattr(incusos, "run", flasher)
    result = CliRunner().invoke(
        app, ["incusos", "image", "--arch", arch, "--output", str(output)]
    )
    assert result.exit_code == 0, result.output
    assert output.read_bytes() == b"downloaded image with seed"
    assert not list(tmp_path.glob(".incusos.*"))


def test_image_preserves_existing_output(tmp_path, monkeypatch):
    monkeypatch.setattr(incusos, "client_ca", lambda: "PUBLIC CLIENT CA")
    output = tmp_path / "install.img"
    output.write_bytes(b"keep existing image")
    monkeypatch.setattr(
        incusos, "run", lambda *a, **kw: pytest.fail("unexpected download")
    )
    result = CliRunner().invoke(
        app, ["incusos", "image", "--arch", "x86_64-linux", "--output", str(output)]
    )
    assert result.exit_code != 0
    assert output.read_bytes() == b"keep existing image"
