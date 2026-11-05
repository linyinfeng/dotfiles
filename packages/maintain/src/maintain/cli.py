"""Maintenance tasks that used to be ad-hoc shell in the devshell."""

from typing import Literal

import typer
from typer.completion import get_completion_script

from maintain import ca, incusos, secrets, terraform, tools

app = typer.Typer(help="maintenance CLI for this repository")
app.add_typer(ca.app, name="ca")
app.add_typer(incusos.app, name="incusos")
app.add_typer(secrets.app, name="secrets")
app.add_typer(terraform.app, name="terraform")
app.add_typer(tools.boot_sd, name="boot-sd")
app.add_typer(tools.patches, name="patches")
app.add_typer(tools.prepare, name="prepare")


@app.command()
def completion(shell: Literal["bash", "fish"]) -> None:
    """Print a shell completion script."""
    typer.echo(
        get_completion_script(
            prog_name="maintain", complete_var="_MAINTAIN_COMPLETE", shell=shell
        )
    )


def main() -> None:
    app()
