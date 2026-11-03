# Servers trust the dedicated Incus client CA. Leaf renewal does not require
# replacing the trusted CA in servers or installation images.
resource "tls_private_key" "incus_terraform_client" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"

  lifecycle {
    prevent_destroy = true
  }
}

resource "tls_cert_request" "incus_terraform_client" {
  private_key_pem = tls_private_key.incus_terraform_client.private_key_pem

  subject {
    common_name  = "incus-terraform"
    organization = "Yinfeng"
  }
}

resource "tls_locally_signed_cert" "incus_terraform_client" {
  cert_request_pem   = tls_cert_request.incus_terraform_client.cert_request_pem
  ca_private_key_pem = local.ca_issuers.incus.private_key_pem
  ca_cert_pem        = local.ca_issuers.incus.cert_pem

  validity_period_hours = 2160 # 90 days
  early_renewal_hours   = 720  # 30 days
  allowed_uses          = ["client_auth"]
}

output "incus_terraform_client_cert_pem" {
  value = tls_locally_signed_cert.incus_terraform_client.cert_pem
}

output "incus_terraform_client_cert_chain_pem" {
  value = "${trimspace(tls_locally_signed_cert.incus_terraform_client.cert_pem)}\n${trimspace(local.ca_issuers.incus.cert_pem)}\n"
}

output "incus_terraform_client_private_key_pem" {
  value     = tls_private_key.incus_terraform_client.private_key_pem
  sensitive = true
}
