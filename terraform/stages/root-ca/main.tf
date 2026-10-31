# This state is encrypted only to personal PGP recipients, never the CI age key.
# Keep the root separate from pre-nixos until intermediates are introduced.
resource "tls_private_key" "root_ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"

  lifecycle {
    prevent_destroy = true
  }
}

resource "tls_self_signed_cert" "root_ca" {
  private_key_pem = tls_private_key.root_ca.private_key_pem

  subject {
    common_name  = "Yinfeng Root CA"
    organization = "Yinfeng"
  }

  validity_period_hours = 100 * 365 * 24 # 100 years
  early_renewal_hours   = 0
  is_ca_certificate     = true
  max_path_length       = 1
  set_subject_key_id    = true
  set_authority_key_id  = true
  allowed_uses          = ["cert_signing", "crl_signing"]

  lifecycle {
    prevent_destroy = true
  }
}

output "root_ca_cert_pem" {
  value = tls_self_signed_cert.root_ca.cert_pem
}

output "root_ca_validity_end_time" {
  value = tls_self_signed_cert.root_ca.validity_end_time
}
