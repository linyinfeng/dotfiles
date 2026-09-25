from maintain.cli import sops_files


def test_sops_files(tmp_path):
    (tmp_path / "secrets/nixos").mkdir(parents=True)
    (tmp_path / "secrets/nixos/host.yaml").write_text("")
    (tmp_path / "secrets/README.md").write_text("")

    assert [p.name for p in sops_files(tmp_path)] == ["host.yaml"]
