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
