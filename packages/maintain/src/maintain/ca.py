"""certificate authority checks over the rendered repository data."""

import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Annotated

import typer
from cryptography import x509

from maintain.common import data_extract_dir, message

app = typer.Typer(help="certificate authority checks")

# the rendered data marks CA certificates by name; leaves (acme_*, secure_boot_*)
# and the legacy ca_cert_pem are deliberately left out of this check
CA_PATH_HINTS = ("root_ca", "intermediate_ca")

# intermediates keep every version around; only the newest one has to stay valid
VERSIONED_NAME = re.compile(r"^(?P<family>.+)-v(?P<version>\d+)$")


def collect_certificates(
    value: object, path: tuple[str, ...] = ()
) -> list[tuple[tuple[str, ...], str]]:
    """Every PEM certificate in VALUE, with the path it sits at."""
    if isinstance(value, str):
        return [(path, value)] if "BEGIN CERTIFICATE" in value else []
    if isinstance(value, dict):
        return [
            found
            for key, item in value.items()
            for found in collect_certificates(item, (*path, str(key)))
        ]
    if isinstance(value, list):
        return [
            found
            for index, item in enumerate(value)
            for found in collect_certificates(item, (*path, str(index)))
        ]
    return []


def versioned_name(path: tuple[str, ...]) -> tuple[str, int] | None:
    """Split a `<family>-v<number>` path component into its family and version."""
    for part in path:
        match = VERSIONED_NAME.match(part)
        if match is not None:
            return match.group("family"), int(match.group("version"))
    return None


def certificate_expiry(pem: str) -> tuple[str, datetime]:
    """Subject and expiry of PEM."""
    certificate = x509.load_pem_x509_certificate(pem.encode())
    return certificate.subject.rfc4514_string(), certificate.not_valid_after_utc


@app.command("check-expiry")
def check_expiry(
    data: Annotated[
        Path | None,
        typer.Option(
            help="rendered data.json to inspect; defaults to lib/data/data.json"
        ),
    ] = None,
    min_days: Annotated[
        int,
        typer.Option(help="fail when a certificate expires within this many days"),
    ] = 365,
) -> None:
    """Fail when a CA certificate expires within --min-days.

    Reads the rendered data, so it needs neither terraform nor the secrets
    repository. Versioned intermediates (`<family>-v<number>`, e.g. `mesh-v1`) are
    kept across rotations, so only their newest version is checked.
    """
    source = data or data_extract_dir() / "data.json"
    try:
        rendered = json.loads(source.read_text())
    except (OSError, json.JSONDecodeError) as error:
        message(f"cannot read '{source}': {error}")
        raise typer.Exit(2) from error

    now = datetime.now(timezone.utc)
    entries: list[tuple[str, datetime]] = []
    newest: dict[str, tuple[int, str, datetime]] = {}
    versions: dict[str, set[int]] = {}

    for path, pem in collect_certificates(rendered):
        if not any(hint in part for part in path for hint in CA_PATH_HINTS):
            continue
        try:
            subject, not_after = certificate_expiry(pem)
        except ValueError as error:
            message(f"cannot parse the certificate at {'/'.join(path)}: {error}")
            raise typer.Exit(2) from error
        versioned = versioned_name(path)
        if versioned is None:
            entries.append((subject, not_after))
            continue
        family, version = versioned
        versions.setdefault(family, set()).add(version)
        known = newest.get(family)
        if known is None or version > known[0]:
            newest[family] = (version, subject, not_after)

    entries.extend((subject, not_after) for _, subject, not_after in newest.values())
    superseded = sum(len(found) - 1 for found in versions.values())
    if superseded:
        message(f"skipping {superseded} superseded certificate version(s)")

    if not entries:
        message(f"no CA certificate in '{source}'")
        raise typer.Exit(2)

    expiring: list[str] = []
    seen: set[str] = set()
    for subject, not_after in entries:
        if subject in seen:
            continue
        seen.add(subject)
        days = (not_after - now).days
        message(f"{subject} expires {not_after:%Y-%m-%d} ({days} days left)")
        if days < min_days:
            expiring.append(f"{subject} ({days} days)")

    if expiring:
        message(f"certificates expiring within {min_days} days: {', '.join(expiring)}")
        raise typer.Exit(1)
