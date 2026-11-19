"""Preserve hardware trust when systemd-boot enrolls IncusOS keys in Setup Mode."""

import json
import os
import struct
import subprocess
import tempfile
import uuid
from datetime import UTC, datetime
from pathlib import Path

from cryptography import x509
from cryptography.hazmat.primitives.serialization import Encoding

X509 = uuid.UUID("a5c059a1-94e4-4aa7-87b5-ab155c2bf072").bytes_le
SHA256 = uuid.UUID("c1c41626-504c-4092-aca9-41f936934328").bytes_le
PKCS7 = uuid.UUID("4aafd29d-68df-49ee-8aa9-347d375665a7").bytes_le
OWNER = uuid.UUID("e58e05e2-5c43-4ef7-880b-3f06734eb36f").bytes_le


def entries(data: bytes) -> list[tuple[bytes, bytes, bytes]]:
    """Read complete EFI signature lists; reject malformed or unsupported input."""
    result = []
    offset = 0
    while offset < len(data):
        if len(data) - offset < 28:
            raise ValueError("truncated EFI signature list")
        kind, size, header, signature = struct.unpack_from("<16sIII", data, offset)
        if (
            size < 28 + header
            or offset + size > len(data)
            or signature <= 16
            or (size - 28 - header) % signature
        ):
            raise ValueError("invalid EFI signature list size")
        for start in range(offset + 28 + header, offset + size, signature):
            owner = data[start : start + 16]
            payload = data[start + 16 : start + signature]
            if kind == X509:
                x509.load_der_x509_certificate(payload)
            elif kind != SHA256 or len(payload) != 32:
                raise ValueError("unsupported EFI signature type")
            result.append((kind, owner, payload))
        offset += size
    return result


def merge(*databases: bytes) -> bytes:
    seen = set()
    output = bytearray()
    for database in databases:
        for kind, owner, payload in entries(database):
            identity = (kind, payload)
            if identity in seen:
                continue
            seen.add(identity)
            output.extend(
                struct.pack("<16sIII", kind, 44 + len(payload), 0, 16 + len(payload))
            )
            output.extend(owner + payload)
    return bytes(output)


def auth_payload(data: bytes) -> bytes:
    if len(data) < 40:
        raise ValueError("truncated authenticated variable")
    size, revision, kind, guid = struct.unpack_from("<IHH16s", data, 16)
    if (
        size < 24
        or 16 + size > len(data)
        or (revision, kind, guid) != (0x200, 0xEF1, PKCS7)
    ):
        raise ValueError("invalid authenticated variable header")
    payload = data[16 + size :]
    if not entries(payload):
        raise ValueError("empty Secure Boot database")
    return payload


def setup_auth(payload: bytes) -> bytes:
    """Unsigned AUTH2 envelope: accepted only in Setup Mode, before PK enrollment.

    UEFI skips signature authentication for PK/KEK/db/dbx in Setup Mode, but
    still requires the EFI_VARIABLE_AUTHENTICATION_2 descriptor. No private
    key is needed or embedded. This is not a signed update for User Mode.
    """
    if not entries(payload):
        raise ValueError("refusing to enroll an empty database")
    now = datetime.now(UTC)
    timestamp = struct.pack(
        "<H6BIh2B",
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute,
        now.second,
        0,
        0,
        0,
        0,
        0,
    )
    return timestamp + struct.pack("<IHH16s", 24, 0x200, 0xEF1, PKCS7) + payload


# Host-specific certs under packages/incusos-secureboot/hosts/<host>/
# (e.g. ostrich: exported from GIGABYTE B650I AX rev.1.0 F41e).
def extra_database(directory: Path, hostname: str, variable: str) -> bytes:
    databases = []
    microsoft = os.environ.get("MAINTAIN_SECUREBOOT_MICROSOFT")
    sources = [(directory / "hosts" / hostname / variable, "*.pem")]
    if microsoft and variable in ("KEK", "db"):
        source = Path(microsoft) / variable.upper() / "Certificates"
        if not source.is_dir():
            raise ValueError(f"missing NUR Microsoft certificate directory: {source}")
        sources.insert(0, (source, "*.der"))
    for root, pattern in sources:
        for path in sorted(root.glob(pattern)):
            loader = (
                x509.load_der_x509_certificate
                if pattern == "*.der"
                else x509.load_pem_x509_certificate
            )
            cert = loader(path.read_bytes())
            payload = cert.public_bytes(Encoding.DER)
            databases.append(
                struct.pack("<16sIII", X509, 44 + len(payload), 0, 16 + len(payload))
                + OWNER
                + payload
            )
    esl = directory / "hosts" / hostname / f"{variable}.esl"
    if esl.exists():
        databases.append(esl.read_bytes())
    return merge(*databases)


def add_secure_boot_certificates(image: Path, hostname: str, directory: Path) -> None:
    """Patch only ESP enrollment files, keeping upstream PK and signed OS intact."""
    additions = {
        name: extra_database(directory, hostname, name) for name in ("KEK", "db", "dbx")
    }
    if not any(additions.values()):
        return
    table = json.loads(subprocess.check_output(["sfdisk", "--json", str(image)]))[
        "partitiontable"
    ]
    esp = [
        p
        for p in table["partitions"]
        if p["type"].lower() == "c12a7328-f81f-11d2-ba4b-00a0c93ec93b"
    ]
    if len(esp) != 1:
        raise ValueError("expected exactly one EFI system partition")
    volume = f"{image}@@{esp[0]['start'] * table.get('sectorsize', 512)}"
    with tempfile.TemporaryDirectory(prefix=".secureboot.", dir=image.parent) as tmp:
        work = Path(tmp)
        # Validate and prepare every replacement before modifying the image.
        replacements = []
        for name, extra in additions.items():
            if not extra:
                continue
            source = f"::/loader/keys/auto/{name}.auth"
            target = work / f"{name}.auth"
            subprocess.run(["mcopy", "-i", volume, source, str(target)], check=True)
            original = auth_payload(target.read_bytes())
            target.write_bytes(setup_auth(merge(original, extra)))
            replacements.append((source, target))
        for destination, source in replacements:
            subprocess.run(
                ["mcopy", "-o", "-i", volume, str(source), destination], check=True
            )
            readback = work / "readback.auth"
            subprocess.run(
                ["mcopy", "-o", "-i", volume, destination, str(readback)], check=True
            )
            if readback.read_bytes() != source.read_bytes():
                raise ValueError("Secure Boot enrollment file readback mismatch")
