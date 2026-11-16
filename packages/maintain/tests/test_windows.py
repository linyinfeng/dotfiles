import hashlib
import json
import tarfile
import xml.etree.ElementTree as ET
from pathlib import Path
from types import SimpleNamespace

import pytest
import typer
from typer.testing import CliRunner

from maintain import windows
from maintain.cli import app


def iso_file(path):
    path.write_bytes(b"\0" * 0x8000 + b"\1CD001" + b"\0" * 2048)
    return path


def test_unattended_selects_pro_and_preserves_private_values():
    password = 'test<&"password'
    root = ET.fromstring(
        windows.unattended("en-US", "Yinfeng", "ostrich-win", password)
    )
    ns = {"u": "urn:schemas-microsoft-com:unattend"}
    assert root.find(".//u:InstallFrom/u:MetaData/u:Value", ns).text == "Windows 11 Pro"
    assert root.find(".//u:ProductKey/u:Key", ns) is None
    assert root.find(".//u:InstallTo/u:PartitionID", ns).text == "4"
    assert root.find(".//u:LocalAccount/u:Name", ns).text == "Yinfeng"
    assert root.find(".//u:LocalAccount/u:Password/u:Value", ns).text == password
    assert root.find(".//u:AutoLogon/u:LogonCount", ns).text == "1"
    assert root.find(".//u:PreventDeviceEncryption", ns).text == "true"
    assert (
        root.find(".//u:DriverPaths/u:PathAndCredentials/u:Path", ns).text
        == r"E:\drivers\viostor\w11\amd64"
    )
    assert "BypassTPMCheck" not in ET.tostring(root).decode()


@pytest.mark.parametrize(
    "url",
    [
        "http://microsoft.com/win.iso",
        "https://example.com/win.iso",
        "https://microsoft.com.evil.test/a.iso",
        "https://user:pass@microsoft.com/a.iso",
    ],
)
def test_only_official_https_iso_links(url):
    with pytest.raises(typer.BadParameter):
        windows.microsoft_url(url)


@pytest.mark.parametrize(
    "locale,language", [("en-US", "English"), ("zh-CN", "Chinese (Simplified)")]
)
def test_microsoft_download_flow(monkeypatch, locale, language):
    calls = []

    def request(url, **kwargs):
        calls.append(url)
        if "software-download/windows11" in url:
            return b'<option value="3813">Windows 11 (multi-edition ISO for x64 devices)</option>'
        if "vlscppe" in url:
            return b""
        if "getskuinformation" in url:
            return json.dumps({"Skus": [{"Id": 123, "Language": language}]}).encode()
        assert kwargs["referer"].endswith("windows11")
        return json.dumps(
            {
                "ProductDownloadOptions": [
                    {
                        "Uri": "https://software.download.prss.microsoft.com/Win11_x64.iso?token=test"
                    }
                ]
            }
        ).encode()

    monkeypatch.setattr(windows, "request", request)
    assert windows.windows_url(locale).startswith(
        "https://software.download.prss.microsoft.com/"
    )
    assert len(calls) == 4
    assert "SKU=123" in calls[-1]


def test_download_rejection_explains_manual_fallback(monkeypatch):
    monkeypatch.setattr(windows, "request", lambda *args, **kwargs: b"blocked")
    with pytest.raises(typer.BadParameter, match="--iso-url"):
        windows.windows_url("en-US")


def test_iso_validation_rejects_html_and_wrong_hash(tmp_path):
    path = tmp_path / "windows.iso"
    path.write_text("<html>download blocked</html>")
    with pytest.raises(typer.BadParameter, match="not an ISO9660"):
        windows.verify_iso(path, None)
    iso_file(path)
    with pytest.raises(typer.BadParameter, match="SHA-256 mismatch"):
        windows.verify_iso(path, "0" * 64)
    windows.verify_iso(path, hashlib.sha256(path.read_bytes()).hexdigest())


def test_download_is_resumable_and_reuses_cache(tmp_path, monkeypatch):
    calls = []
    monkeypatch.setattr(
        windows,
        "windows_url",
        lambda locale: "https://software.download.prss.microsoft.com/Win11_x64.iso",
    )

    def download(command, **kwargs):
        assert command[:2] == ["curl", "--fail"]
        assert command[command.index("--continue-at") + 1] == "-"
        iso_file(Path(command[command.index("--output") + 1]))
        calls.append(command)

    monkeypatch.setattr(windows, "run", download)
    result = windows.obtain_iso(tmp_path, "en-US", None, None)
    assert result.is_file()
    assert windows.obtain_iso(tmp_path, "en-US", None, None) == result
    assert len(calls) == 1
    assert not list(tmp_path.glob("*.part"))


@pytest.fixture
def build_environment(tmp_path, monkeypatch):
    monkeypatch.setenv("DOTFILES_DIR", str(tmp_path))
    drivers = tmp_path / "virtio"
    (drivers / "viostor/w11/amd64").mkdir(parents=True)
    (drivers / "viostor/w11/amd64/viostor.inf").write_text("driver")
    (drivers / "guest-agent").mkdir()
    (drivers / "guest-agent/qemu-ga-x86_64.msi").write_bytes(b"MSI")
    monkeypatch.setenv("MAINTAIN_WINDOWS_DRIVERS", str(drivers))
    monkeypatch.setenv("MAINTAIN_WINDOWS_FIRMWARE", str(tmp_path / "code.fd"))
    monkeypatch.setenv("MAINTAIN_WINDOWS_VARIABLES", str(tmp_path / "vars.fd"))
    monkeypatch.setattr(windows.os, "access", lambda *args: True)
    monkeypatch.setattr(windows.platform, "machine", lambda: "x86_64")
    monkeypatch.setattr(windows.shutil, "which", lambda command: "/bin/" + command)
    calls = []

    def run(command, **kwargs):
        calls.append(command)
        if command[0] == "xorriso":
            stage = Path(command[-1])
            assert (stage / "autounattend.xml").is_file()
            assert (stage / "IncusBootstrap.ps1").is_file()
            Path(command[command.index("-o") + 1]).write_bytes(b"private seed")

    monkeypatch.setattr(windows, "run", run)

    def install(target, iso, cpus, memory, timeout, vnc):
        assert target.stat().st_mode & 0o777 == 0o700
        (target / "rootfs.qcow2").write_bytes(b"completed private disk")

    monkeypatch.setattr(windows, "install", install)
    return iso_file(tmp_path / "Win11.iso"), calls


def test_build_writes_private_credentials_and_incus_metadata(
    tmp_path, build_environment
):
    source, calls = build_environment
    password = tmp_path / "password"
    password.write_text("test-password\n")
    password.chmod(0o600)
    result = CliRunner().invoke(
        app,
        ["windows", "image", "--iso", str(source), "--password-file", str(password)],
    )
    assert result.exit_code == 0, result.output
    assert "test-password" not in result.output
    target = tmp_path / ".data/windows/windows-image"
    assert json.loads((target / "credentials.json").read_text()) == {
        "username": "Yinfeng",
        "password": "test-password",
    }
    assert all(
        path.stat().st_mode & 0o777 == 0o600
        for path in target.iterdir()
        if path.is_file()
    )
    with tarfile.open(target / "metadata.tar.xz") as archive:
        data = json.load(archive.extractfile("metadata.yaml"))
    assert data["architecture"] == "x86_64"
    assert data["properties"]["os"] == "Windows"
    assert data["properties"]["requirements.cdrom_agent"] == "true"
    assert not any(command[0] == "incus" for command in calls)
    assert not list(target.glob(".seed.*"))


def test_failed_install_does_not_publish_image(
    tmp_path, build_environment, monkeypatch
):
    source, calls = build_environment

    def fail(*args):
        raise RuntimeError("installer failed")

    monkeypatch.setattr(windows, "install", fail)
    result = CliRunner().invoke(app, ["windows", "image", "--iso", str(source)])
    assert result.exit_code != 0
    target = tmp_path / ".data/windows/windows-image"
    assert not (target / "metadata.tar.xz").exists()
    assert "image ready:" not in result.output
    assert not any(command[0] == "incus" for command in calls)


def test_existing_output_is_never_overwritten(tmp_path, build_environment):
    source, calls = build_environment
    target = tmp_path / "existing"
    target.mkdir()
    (target / "keep").write_text("keep")
    result = CliRunner().invoke(
        app, ["windows", "image", "--iso", str(source), "--output", str(target)]
    )
    assert result.exit_code != 0
    assert (target / "keep").read_text() == "keep"
    assert calls == []


def test_import_only_after_success(tmp_path, build_environment, monkeypatch):
    source, calls = build_environment
    monkeypatch.setattr(
        windows.subprocess, "run", lambda *args, **kwargs: SimpleNamespace(stdout="[]")
    )
    result = CliRunner().invoke(
        app, ["windows", "image", "--iso", str(source), "--import-to", "ostrich-mtls"]
    )
    assert result.exit_code == 0, result.output
    assert calls[-1][:3] == ["incus", "image", "import"]
    assert calls[-1][-3:] == ["ostrich-mtls:", "--alias", "windows-initial"]


def test_import_refuses_existing_alias(tmp_path, build_environment, monkeypatch):
    source, calls = build_environment
    monkeypatch.setattr(
        windows.subprocess,
        "run",
        lambda *args, **kwargs: SimpleNamespace(stdout='[{"name":"windows-initial"}]'),
    )
    result = CliRunner().invoke(
        app, ["windows", "image", "--iso", str(source), "--import-to", "ostrich-mtls"]
    )
    assert result.exit_code != 0
    assert "already exists" in result.output
    assert calls == []


def test_qemu_paths_escape_commas():
    assert windows.qemu_path(Path("/tmp/some, disk.qcow2")) == "/tmp/some,, disk.qcow2"


@pytest.mark.parametrize("completed", [False, True])
def test_clean_qemu_exit_requires_explicit_completion(tmp_path, monkeypatch, completed):
    target = tmp_path / "output"
    target.mkdir()
    variables = tmp_path / "vars.fd"
    variables.write_bytes(b"firmware variables")
    monkeypatch.setenv("MAINTAIN_WINDOWS_VARIABLES", str(variables))
    monkeypatch.setenv("MAINTAIN_WINDOWS_FIRMWARE", str(tmp_path / "code.fd"))
    calls = []
    cleaned = []
    monkeypatch.setattr(windows, "run", lambda command, **kwargs: calls.append(command))

    class Process:
        returncode = 0

        def __init__(self, command, **kwargs):
            self.tpm = command[0] == "swtpm"
            self.stopped = False
            if self.tpm:
                option = next(
                    arg for arg in command if arg.startswith("type=unixio,path=")
                )
                Path(option.split("path=", 1)[1]).touch()
            elif completed:
                (target / "serial.log").write_bytes(windows.READY)

        def poll(self):
            return None if self.tpm and not self.stopped else 0

        def terminate(self):
            cleaned.append("tpm")
            self.stopped = True

        def wait(self, **kwargs):
            return 0

    monkeypatch.setattr(windows.subprocess, "Popen", Process)
    if completed:
        windows.install(target, tmp_path / "win.iso", 4, 8192, 60, None)
        assert calls[-1] == ["qemu-img", "check", str(target / "rootfs.qcow2")]
    else:
        with pytest.raises(RuntimeError, match="without completing provisioning"):
            windows.install(target, tmp_path / "win.iso", 4, 8192, 60, None)
        assert not any("check" in command for command in calls)
    assert cleaned == ["tpm"]
