import json
import tarfile
from types import SimpleNamespace

import pytest
from typer.testing import CliRunner

from maintain import incusos
from maintain.cli import app


@pytest.fixture
def seed_configuration(tmp_path, monkeypatch):
    directory = tmp_path / "packages/incusos-seed"
    directory.mkdir(parents=True)
    for name, value in {
        "install.json": {},
        "applications.json": {"applications": [{"name": "incus"}]},
        "incus.json": {"apply_defaults": True, "preseed": {}},
        "services.json": {"version": "1", "tailscale": {"enabled": True}},
    }.items():
        (directory / name).write_text(json.dumps(value))
    monkeypatch.setenv("DOTFILES_DIR", str(tmp_path))
    monkeypatch.setattr(incusos, "tailscale_auth_key", lambda: "tskey-auth-test")


@pytest.mark.parametrize("arch", ["x86_64-linux", "aarch64-linux"])
def test_image_seeds_ca_without_forcing_install(
    tmp_path, monkeypatch, arch, seed_configuration
):
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
            assert json.load(archive.extractfile("network.json")) == {
                "dns": {"hostname": "test-host"}
            }
            tailscale = json.load(archive.extractfile("services.json"))["tailscale"]
            assert tailscale == {"enabled": True, "auth_key": "tskey-auth-test"}
        assert "tskey-auth-test" not in command
        assert "tskey-auth-test" not in env.values()
        (cwd / "upstream.img").write_bytes(b"downloaded image with seed")

    monkeypatch.setattr(incusos, "run", flasher)
    result = CliRunner().invoke(
        app,
        [
            "incusos",
            "image",
            "--hostname",
            "test-host",
            "--arch",
            arch,
            "--output",
            str(output),
        ],
    )
    assert result.exit_code == 0, result.output
    assert "tskey-auth-test" not in result.output
    assert output.read_bytes() == b"downloaded image with seed"
    assert output.stat().st_mode & 0o777 == 0o600
    assert not list(tmp_path.glob(".incusos.*"))


def test_image_preserves_existing_output(tmp_path, monkeypatch, seed_configuration):
    monkeypatch.setattr(incusos, "client_ca", lambda: "PUBLIC CLIENT CA")
    output = tmp_path / "install.img"
    output.write_bytes(b"keep existing image")
    monkeypatch.setattr(
        incusos, "run", lambda *a, **kw: pytest.fail("unexpected download")
    )
    result = CliRunner().invoke(
        app,
        [
            "incusos",
            "image",
            "--hostname",
            "test-host",
            "--arch",
            "x86_64-linux",
            "--output",
            str(output),
        ],
    )
    assert result.exit_code != 0
    assert output.read_bytes() == b"keep existing image"


@pytest.mark.parametrize("arch", ["x86_64-linux", "aarch64-linux"])
@pytest.mark.parametrize("version", ["202611020428", "202611112343"])
def test_image_default_filename_includes_hostname_arch_and_version(
    tmp_path, monkeypatch, seed_configuration, arch, version
):
    monkeypatch.setattr(incusos, "client_ca", lambda: "PUBLIC CLIENT CA")

    def flasher(command, *, cwd, env):
        (cwd / f"IncusOS_{version}.img").write_bytes(b"seeded image")

    monkeypatch.setattr(incusos, "run", flasher)
    for hostname in ["ostrich", "parrot"]:
        result = CliRunner().invoke(
            app, ["incusos", "image", "--arch", arch, "--hostname", hostname]
        )
        assert result.exit_code == 0, result.output
        image = tmp_path / ".data/incusos" / f"incusos-{hostname}-{arch}-{version}.img"
        assert image.read_bytes() == b"seeded image"
        assert str(image) in result.output

        result = CliRunner().invoke(
            app, ["incusos", "image", "--arch", arch, "--hostname", hostname]
        )
        assert result.exit_code != 0
        assert image.read_bytes() == b"seeded image"


def test_image_default_filename_rejects_unknown_upstream_version(
    tmp_path, monkeypatch, seed_configuration
):
    monkeypatch.setattr(incusos, "client_ca", lambda: "PUBLIC CLIENT CA")

    def flasher(command, *, cwd, env):
        (cwd / "unknown.img").write_bytes(b"image")

    monkeypatch.setattr(incusos, "run", flasher)
    result = CliRunner().invoke(
        app, ["incusos", "image", "--hostname", "ostrich", "--arch", "x86_64-linux"]
    )
    assert result.exit_code != 0
    assert "cannot determine IncusOS version" in result.output
    assert not list((tmp_path / ".data/incusos").glob("*.img"))


@pytest.mark.parametrize("command", ["seed", "image"])
@pytest.mark.parametrize(
    ("flags", "expected"),
    [([], False), (["--force-install"], True), (["--no-force-install"], False)],
)
def test_generation_controls_install_overwrite_policy(
    tmp_path, monkeypatch, seed_configuration, command, flags, expected
):
    monkeypatch.setattr(incusos, "client_ca", lambda: "PUBLIC CLIENT CA")
    install = {"force_install": not expected, "target": {"id": "test-disk"}}
    (tmp_path / "packages/incusos-seed/install.json").write_text(json.dumps(install))
    output = tmp_path / ("install.img" if command == "image" else "seed.tar")

    def check_seed(path):
        with tarfile.open(path) as archive:
            config = json.load(archive.extractfile("install.json"))
        assert config == {"force_install": expected, "target": {"id": "test-disk"}}

    def flasher(args, *, cwd, env):
        assert args[0] == "flasher-tool"
        check_seed(args[args.index("--seed") + 1])
        (cwd / "upstream.img").write_bytes(b"seeded image")

    monkeypatch.setattr(incusos, "run", flasher)
    args = [
        "incusos",
        command,
        "--hostname",
        "ostrich",
        "--output",
        str(output),
        *flags,
    ]
    if command == "image":
        args += ["--arch", "x86_64-linux"]
    result = CliRunner().invoke(app, args)
    assert result.exit_code == 0, result.output
    if command == "seed":
        check_seed(output)
    assert output.stat().st_mode & 0o777 == 0o600


def test_seed_generates_private_archive_without_overwriting(
    tmp_path, monkeypatch, seed_configuration
):
    monkeypatch.setattr(incusos, "client_ca", lambda: "PUBLIC CLIENT CA")
    output = tmp_path / "seed.tar"
    result = CliRunner().invoke(
        app, ["incusos", "seed", "--hostname", "test-host", "--output", str(output)]
    )
    assert result.exit_code == 0, result.output
    assert "tskey-auth-test" not in result.output
    assert output.stat().st_mode & 0o777 == 0o600
    with tarfile.open(output) as archive:
        assert (
            json.load(archive.extractfile("network.json"))["dns"]["hostname"]
            == "test-host"
        )
        assert json.load(archive.extractfile("services.json"))["tailscale"] == {
            "enabled": True,
            "auth_key": "tskey-auth-test",
        }
        config = json.load(archive.extractfile("incus.json"))
        assert config["preseed"]["certificates"][0]["certificate"] == "PUBLIC CLIENT CA"

    output.write_bytes(b"keep existing seed")
    result = CliRunner().invoke(
        app, ["incusos", "seed", "--hostname", "test-host", "--output", str(output)]
    )
    assert result.exit_code != 0
    assert output.read_bytes() == b"keep existing seed"


def test_seed_rejects_missing_configuration(tmp_path, monkeypatch, seed_configuration):
    monkeypatch.setattr(incusos, "client_ca", lambda: "PUBLIC CLIENT CA")
    monkeypatch.setenv("DOTFILES_DIR", str(tmp_path / "missing"))
    output = tmp_path / "seed.tar"
    result = CliRunner().invoke(
        app, ["incusos", "seed", "--hostname", "test-host", "--output", str(output)]
    )
    assert result.exit_code != 0
    assert "cannot load IncusOS seed configuration" in result.output
    assert not output.exists()


@pytest.mark.parametrize("command", ["seed", "image"])
@pytest.mark.parametrize("hostname", [None, "", "-bad", "bad-", "bad.name", "a" * 64])
def test_generation_requires_valid_hostname(command, hostname, monkeypatch):
    def unexpected():
        pytest.fail(
            "hostname must be validated before accessing certificates or secrets"
        )

    monkeypatch.setattr(incusos, "client_ca", unexpected)
    monkeypatch.setattr(incusos, "tailscale_auth_key", unexpected)
    args = ["incusos", command]
    if command == "image":
        args += ["--arch", "x86_64-linux"]
    if hostname is not None:
        args += ["--hostname", hostname]
    result = CliRunner().invoke(app, args)
    assert result.exit_code == 2, result.output
    assert "hostname" in result.output.lower()


def test_seed_hostname_preserves_network_settings(
    tmp_path, monkeypatch, seed_configuration
):
    monkeypatch.setattr(incusos, "client_ca", lambda: "PUBLIC CLIENT CA")
    network = {
        "dns": {"hostname": "old-host", "domain": "example.com"},
        "interfaces": [{"name": "uplink", "addresses": ["dhcp4", "slaac"]}],
    }
    (tmp_path / "packages/incusos-seed/network.json").write_text(json.dumps(network))
    output = tmp_path / "seed.tar"
    result = CliRunner().invoke(
        app, ["incusos", "seed", "--hostname", "new-host", "--output", str(output)]
    )
    assert result.exit_code == 0, result.output
    network["dns"]["hostname"] = "new-host"
    with tarfile.open(output) as archive:
        assert json.load(archive.extractfile("network.json")) == network


@pytest.mark.parametrize(
    ("returncode", "stdout", "error"),
    [
        (0, "tskey-auth-test\n", None),
        (0, "", "not a Tailscale auth key"),
        (0, "unexpected-secret", "not a Tailscale auth key"),
        (1, "tskey-auth-secret", "cannot decrypt Tailscale auth key"),
    ],
)
def test_tailscale_auth_key_extracts_only_key_without_disclosing_errors(
    tmp_path, monkeypatch, returncode, stdout, error
):
    monkeypatch.setenv("SECRETS_DIR", str(tmp_path))

    def decrypt(command, **kwargs):
        assert command == [
            "sops",
            "--decrypt",
            "--extract",
            '["tailscale_tailnet_key"]["value"]',
            str(tmp_path / "terraform/outputs/pre-nixos.yaml"),
        ]
        assert kwargs == {"capture_output": True, "text": True}
        return SimpleNamespace(
            returncode=returncode, stdout=stdout, stderr="sensitive-error-output"
        )

    monkeypatch.setattr(incusos.subprocess, "run", decrypt)
    if error is None:
        assert incusos.tailscale_auth_key() == "tskey-auth-test"
    else:
        with pytest.raises(incusos.typer.BadParameter, match=error) as failure:
            incusos.tailscale_auth_key()
        assert "unexpected-secret" not in str(failure.value)
        assert "tskey-auth-secret" not in str(failure.value)
        assert "sensitive-error-output" not in str(failure.value)


def test_image_aborts_before_download_when_key_decryption_fails(
    tmp_path, monkeypatch, seed_configuration
):
    monkeypatch.setattr(incusos, "client_ca", lambda: "PUBLIC CLIENT CA")

    def fail():
        raise incusos.typer.BadParameter("cannot decrypt Tailscale auth key")

    monkeypatch.setattr(incusos, "tailscale_auth_key", fail)
    monkeypatch.setattr(
        incusos, "run", lambda *a, **kw: pytest.fail("unexpected download")
    )
    output = tmp_path / "install.img"
    result = CliRunner().invoke(
        app,
        [
            "incusos",
            "image",
            "--hostname",
            "test-host",
            "--arch",
            "x86_64-linux",
            "--output",
            str(output),
        ],
    )
    assert result.exit_code != 0
    assert "cannot decrypt Tailscale auth key" in result.output
    assert not output.exists()
    assert not list(tmp_path.glob(".incusos.*"))


@pytest.fixture
def flash_setup(tmp_path, monkeypatch):
    device = tmp_path / "usb-disk"
    device.touch()
    image = tmp_path / "install.img"
    image.write_bytes(bytes(512) + b"EFI PART" + bytes(512))
    partition = f"{device}2"
    disk = {
        "name": str(device),
        "type": "disk",
        "tran": "usb",
        "size": 4096,
        "ro": False,
        "model": "Test USB",
        "serial": "test-serial",
        "mountpoints": [None],
        "children": [
            {
                "name": partition,
                "type": "part",
                "size": 2048,
                "ro": False,
                "partlabel": "seed-data",
                "mountpoints": [None],
            }
        ],
    }
    inspections = []
    commands = []
    monkeypatch.setattr(incusos.Path, "is_block_device", lambda self: self == device)

    def lsblk(command, **kwargs):
        assert command[0] == "lsblk"
        assert command[-1] == str(device)
        inspections.append(command)
        return SimpleNamespace(stdout=json.dumps({"blockdevices": [disk]}))

    monkeypatch.setattr(incusos.subprocess, "run", lsblk)
    monkeypatch.setattr(incusos, "run", lambda command: commands.append(command))
    monkeypatch.setattr(incusos.os, "geteuid", lambda: 0)
    monkeypatch.setattr(incusos.shutil, "which", lambda command: f"/tools/{command}")
    return SimpleNamespace(
        device=device,
        image=image,
        partition=partition,
        disk=disk,
        commands=commands,
        inspections=inspections,
    )


def test_flash_image_uses_whole_disk_and_verifies_bytes(flash_setup):
    setup = flash_setup
    result = CliRunner().invoke(
        app,
        ["incusos", "flash", str(setup.device), "--image", str(setup.image)],
        input="y\n",
    )
    assert result.exit_code == 0, result.output
    assert len(setup.inspections) == 2
    assert "ALL data" in result.output
    assert setup.commands == [
        [
            "/tools/dd",
            f"if={setup.image}",
            f"of={setup.device}",
            "bs=4M",
            "status=progress",
            "conv=fsync,notrunc",
        ],
        [
            "/tools/cmp",
            "--bytes",
            str(setup.image.stat().st_size),
            str(setup.image),
            str(setup.device),
        ],
        ["/tools/blockdev", "--rereadpt", str(setup.device)],
    ]


def test_flash_seed_preserves_other_partitions(flash_setup, tmp_path):
    setup = flash_setup
    seed = tmp_path / "seed.tar"
    with tarfile.open(seed, "w") as archive:
        for name in ["install.json", "incus.json"]:
            archive.addfile(tarfile.TarInfo(name))
    setup.disk["children"][0]["size"] = seed.stat().st_size
    result = CliRunner().invoke(
        app, ["incusos", "flash", str(setup.device), "--seed", str(seed), "--yes"]
    )
    assert result.exit_code == 0, result.output
    assert len(setup.commands) == 2
    assert f"of={setup.partition}" in setup.commands[0]
    assert setup.commands[1][-1] == setup.partition
    assert all("blockdev" not in item for cmd in setup.commands for item in cmd)


def test_flash_confirmation_declined_does_not_write(flash_setup):
    setup = flash_setup
    result = CliRunner().invoke(
        app,
        ["incusos", "flash", str(setup.device), "--image", str(setup.image)],
        input="n\n",
    )
    assert result.exit_code != 0
    assert setup.commands == []


@pytest.mark.parametrize(
    ("change", "error"),
    [
        ({"tran": "nvme"}, "whole USB disk"),
        ({"type": "part"}, "whole USB disk"),
        ({"ro": True}, "read-only"),
        ({"size": 1}, "larger than"),
        ({"mountpoints": ["/"]}, "unmount"),
        ({"mountpoints": ["[SWAP]"]}, "swap"),
        ({"children": [{"name": "mapped", "type": "crypt"}]}, "active block mapping"),
        (
            {
                "children": [
                    {
                        "name": "mounted-partition",
                        "type": "part",
                        "mountpoints": ["/media/usb"],
                    }
                ]
            },
            "unmount",
        ),
    ],
)
def test_flash_rejects_unsafe_targets(flash_setup, change, error):
    setup = flash_setup
    setup.disk.update(change)
    result = CliRunner().invoke(
        app,
        ["incusos", "flash", str(setup.device), "--image", str(setup.image), "--yes"],
    )
    assert result.exit_code != 0
    assert error in result.output
    assert setup.commands == []


def test_flash_refuses_regular_file_target(flash_setup, monkeypatch):
    setup = flash_setup
    monkeypatch.setattr(incusos.Path, "is_block_device", lambda self: False)
    result = CliRunner().invoke(
        app,
        ["incusos", "flash", str(setup.device), "--image", str(setup.image), "--yes"],
    )
    assert result.exit_code != 0
    assert "not a block device" in result.output
    assert setup.commands == []
    assert setup.inspections == []


def test_flash_rechecks_disk_after_confirmation(flash_setup, monkeypatch):
    setup = flash_setup

    def inspect(device):
        setup.inspections.append(device)
        return dict(setup.disk, serial=str(len(setup.inspections)))

    monkeypatch.setattr(incusos, "usb_disk", inspect)
    result = CliRunner().invoke(
        app,
        ["incusos", "flash", str(setup.device), "--image", str(setup.image)],
        input="y\n",
    )
    assert result.exit_code != 0
    assert "target device changed" in result.output
    assert setup.commands == []


def test_flash_requires_exactly_one_source(flash_setup):
    setup = flash_setup
    for args in [
        [],
        ["--image", str(setup.image), "--seed", str(setup.image)],
    ]:
        result = CliRunner().invoke(app, ["incusos", "flash", str(setup.device), *args])
        assert result.exit_code != 0
        assert "exactly one" in result.output
    assert setup.commands == []


def test_flash_refuses_missing_seed_partition(flash_setup, tmp_path):
    setup = flash_setup
    setup.disk["children"] = []
    seed = tmp_path / "seed.tar"
    with tarfile.open(seed, "w") as archive:
        for name in ["install.json", "incus.json"]:
            archive.addfile(tarfile.TarInfo(name))
    result = CliRunner().invoke(
        app, ["incusos", "flash", str(setup.device), "--seed", str(seed), "--yes"]
    )
    assert result.exit_code != 0
    assert "seed-data partition" in result.output
    assert setup.commands == []


@pytest.mark.parametrize("mode", ["image", "seed"])
@pytest.mark.parametrize("yes", [False, True])
def test_flash_non_root_reexecutes_with_run0_before_reading_files(
    flash_setup, tmp_path, monkeypatch, mode, yes
):
    setup = flash_setup
    setup.device.chmod(0)
    setup.image.chmod(0)
    monkeypatch.setattr(incusos.os, "geteuid", lambda: 1000)
    monkeypatch.setattr(incusos.sys, "argv", ["/installed/bin/maintain"])
    monkeypatch.setenv("DOTFILES_DIR", str(tmp_path))
    source = setup.image
    args = [f"--{mode}", str(source)]
    if yes:
        args.append("--yes")
    result = CliRunner().invoke(app, ["incusos", "flash", str(setup.device), *args])
    assert result.exit_code == 0, result.output
    assert setup.commands == [
        [
            "/tools/run0",
            "--",
            "/installed/bin/maintain",
            "incusos",
            "flash",
            str(setup.device),
            "--seed" if mode == "seed" else "--image",
            str(source),
            *(["--yes"] if yes else []),
        ]
    ]
    assert setup.inspections == []


def test_flash_reports_missing_run0_without_touching_device(flash_setup, monkeypatch):
    setup = flash_setup
    monkeypatch.setattr(incusos.os, "geteuid", lambda: 1000)
    monkeypatch.setattr(incusos.shutil, "which", lambda command: None)
    result = CliRunner().invoke(
        app, ["incusos", "flash", str(setup.device), "--image", str(setup.image)]
    )
    assert result.exit_code != 0
    assert "run0 is required" in result.output
    assert setup.commands == []
    assert setup.inspections == []


def test_flash_propagates_run0_failure(flash_setup, monkeypatch):
    setup = flash_setup
    monkeypatch.setattr(incusos.os, "geteuid", lambda: 1000)

    def rejected(command):
        raise incusos.subprocess.CalledProcessError(7, command)

    monkeypatch.setattr(incusos, "run", rejected)
    result = CliRunner().invoke(
        app, ["incusos", "flash", str(setup.device), "--image", str(setup.image)]
    )
    assert result.exit_code == 7
    assert setup.inspections == []
