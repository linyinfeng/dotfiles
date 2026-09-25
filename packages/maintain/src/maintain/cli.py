"""Maintenance tasks that used to be ad-hoc shell in the devshell."""

import typer

from maintain import secrets, terraform

app = typer.Typer(help="maintenance CLI for this repository")
app.add_typer(secrets.app, name="secrets")
app.add_typer(terraform.app, name="terraform")


def main() -> None:
    app()
