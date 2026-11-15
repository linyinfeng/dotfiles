import os
import struct
from pathlib import Path

import pytest
from maintain import incusos_secureboot as sb

CERTIFICATES = Path(
    os.environ.get(
        "INCUSOS_TEST_CERTIFICATES",
        Path(__file__).resolve().parents[2] / "incusos-secureboot",
    )
)


def test_merging_preserves_hardware_certificates_and_revocations():
    kek = sb.extra_database(CERTIFICATES, "ostrich", "KEK")
    db = sb.extra_database(CERTIFICATES, "ostrich", "db")
    dbx = sb.extra_database(CERTIFICATES, "ostrich", "dbx")
    assert len(sb.entries(kek)) == 3
    assert len(sb.entries(db)) == 7
    assert len(sb.entries(dbx)) == 77
    changed_owner = b"".join(
        struct.pack("<16sIII", kind, 44 + len(payload), 0, 16 + len(payload))
        + bytes(16)
        + payload
        for kind, _, payload in sb.entries(db)
    )
    assert sb.merge(db, changed_owner) == db
    for original in (kek, db, dbx):
        auth = sb.setup_auth(original)
        assert len(auth) == 40 + len(original)
        assert struct.unpack_from("<I", auth, 16)[0] == 24
        assert sb.auth_payload(auth) == original
    assert len(sb.entries(sb.extra_database(CERTIFICATES, "other-host", "KEK"))) == 2
    assert len(sb.entries(sb.extra_database(CERTIFICATES, "other-host", "db"))) == 5


@pytest.mark.parametrize("data", [b"x", bytes(28), bytes(40), bytes(100)])
def test_invalid_exports_are_rejected(data):
    with pytest.raises(ValueError):
        sb.entries(data)
    with pytest.raises(ValueError):
        sb.auth_payload(data)


def test_refuses_empty_database():
    with pytest.raises(ValueError, match="empty"):
        sb.setup_auth(b"")
