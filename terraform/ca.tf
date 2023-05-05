resource "tls_private_key" "ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}
resource "tls_self_signed_cert" "ca" {
    is_ca_certificate  = true
    private_key_pem = tls_private_key.ca.private_key_pem
    subject {
        common_name = "li7g.com"
        organization = "Yinfeng"
    }
    validity_period_hours = 8760 # 1 year
    early_renewal_hours   = 4320 # 6 months
    allowed_uses = [
        "crl_signing"
    ]
}
output "ca_cert_pem" {
    value = tls_self_signed_cert.ca.cert_pem
    sensitive = false
}
