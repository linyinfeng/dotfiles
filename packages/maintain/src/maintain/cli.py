"""Maintenance tasks that used to be ad-hoc shell in the devshell."""

import typer

from maintain import secrets

app = typer.Typer(help="maintenance CLI for this repository")
app.add_typer(secrets.app, name="secrets")


def main() -> None:
    app()
