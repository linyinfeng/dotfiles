import json
from datetime import datetime, timedelta, timezone

import pytest
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.x509.oid import NameOID
from typer.testing import CliRunner

from maintain import ca
from maintain.cli import app as maintain_app


def certificate(common_name, days):
    """A self-signed CA certificate expiring DAYS from now."""
    key = ec.generate_private_key(ec.SECP256R1())
    now = datetime.now(timezone.utc)
    name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, common_name)])
    built = (
        x509.CertificateBuilder()
        .subject_name(name)
        .issuer_name(name)
        .public_key(key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(now - timedelta(days=1))
        .not_valid_after(now + timedelta(days=days))
        .add_extension(x509.BasicConstraints(ca=True, path_length=None), critical=True)
        .sign(key, hashes.SHA256())
    )
    return built.public_bytes(serialization.Encoding.PEM).decode()


def render(tmp_path, rendered):
    path = tmp_path / "data.json"
    path.write_text(json.dumps(rendered))
    return path


def check(path, *args):
    return CliRunner().invoke(
        maintain_app, ["ca", "check-expiry", "--data", str(path), *args]
    )


def test_collect_certificates_keeps_the_path_they_sit_at():
    pem = certificate("Root", 3650)

    assert ca.collect_certificates({"a": [{"b": pem}], "c": "not a certificate"}) == [
        (("a", "0", "b"), pem)
    ]


@pytest.mark.parametrize(
    ("path", "expected"),
    [
        (("intermediate_ca_certificates", "mesh-v1"), ("mesh", 1)),
        (
            ("intermediate_ca_certificates", "services-v12", "cert_pem"),
            ("services", 12),
        ),
        (("root_ca_cert_pem",), None),
        (("intermediate_ca_certificates", "root"), None),
    ],
)
def test_versioned_name_splits_family_and_version(path, expected):
    assert ca.versioned_name(path) == expected


def test_check_expiry_passes_when_every_ca_is_far_from_expiry(tmp_path):
    path = render(
        tmp_path,
        {
            "root_ca_cert_pem": certificate("Yinfeng Root CA", 3650),
            "intermediate_ca_certificates": {
                "mesh-v1": certificate("Yinfeng Mesh Intermediate CA v1", 1825)
            },
        },
    )

    result = check(path)

    assert result.exit_code == 0, result.output
    assert "CN=Yinfeng Root CA" in result.output
    assert "CN=Yinfeng Mesh Intermediate CA v1" in result.output


def test_check_expiry_fails_when_a_ca_expires_within_the_window(tmp_path):
    path = render(tmp_path, {"root_ca_cert_pem": certificate("Yinfeng Root CA", 100)})

    result = check(path)

    assert result.exit_code == 1, result.output
    assert "CN=Yinfeng Root CA" in result.output
    assert "expiring within 365 days" in result.output


def test_check_expiry_honours_min_days(tmp_path):
    path = render(tmp_path, {"root_ca_cert_pem": certificate("Yinfeng Root CA", 400)})

    assert check(path, "--min-days", "365").exit_code == 0
    assert check(path, "--min-days", "800").exit_code == 1


def test_check_expiry_only_checks_the_newest_version_of_each_family(tmp_path):
    path = render(
        tmp_path,
        {
            "intermediate_ca_certificates": {
                # the superseded version is about to expire, which must not matter
                "mesh-v1": certificate("Yinfeng Mesh Intermediate CA v1", 10),
                "mesh-v2": certificate("Yinfeng Mesh Intermediate CA v2", 1825),
            }
        },
    )

    result = check(path)

    assert result.exit_code == 0, result.output
    assert "CN=Yinfeng Mesh Intermediate CA v2" in result.output
    assert "CN=Yinfeng Mesh Intermediate CA v1" not in result.output
    assert "skipping 1 superseded certificate version" in result.output


def test_check_expiry_ignores_leaves_and_the_legacy_ca(tmp_path):
    path = render(
        tmp_path,
        {
            "ca_cert_pem": certificate("legacy", 10),
            "acme_li7g_com_certificate_pem": certificate("acme", 10),
            "secure_boot_pk_cert_pem": certificate("secure boot", 10),
        },
    )

    result = check(path)

    assert result.exit_code == 2, result.output
    assert "no CA certificate in" in result.output


def test_check_expiry_rejects_an_unreadable_data_file(tmp_path):
    result = check(tmp_path / "missing.json")

    assert result.exit_code == 2, result.output
    assert "cannot read" in result.output


def test_check_expiry_rejects_a_malformed_certificate(tmp_path):
    path = render(
        tmp_path,
        {
            "root_ca_cert_pem": (
                "-----BEGIN CERTIFICATE-----\nnot base64\n-----END CERTIFICATE-----\n"
            )
        },
    )

    result = check(path)

    assert result.exit_code == 2, result.output
    assert "cannot parse the certificate at root_ca_cert_pem" in result.output


def test_check_expiry_reads_the_rendered_data_by_default(tmp_path, monkeypatch):
    monkeypatch.setenv("DATA_EXTRACT_DIR", str(tmp_path))
    (tmp_path / "data.json").write_text(
        json.dumps({"root_ca_cert_pem": certificate("Yinfeng Root CA", 3650)})
    )

    result = CliRunner().invoke(maintain_app, ["ca", "check-expiry"])

    assert result.exit_code == 0, result.output
    assert "CN=Yinfeng Root CA" in result.output
