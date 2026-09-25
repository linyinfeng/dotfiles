"""Maintenance tasks that used to be ad-hoc shell in the devshell."""

import typer

from maintain import secrets, terraform, tools

app = typer.Typer(help="maintenance CLI for this repository")
app.add_typer(secrets.app, name="secrets")
app.add_typer(terraform.app, name="terraform")
app.add_typer(tools.boot_sd, name="boot-sd")
app.add_typer(tools.patches, name="patches")
app.add_typer(tools.prepare, name="prepare")


def main() -> None:
    app()
