variable "incus_ca_private_key_pem" {
  type      = string
  sensitive = true
}

variable "incus_ca_cert_pem" {
  type = string
}

# Each management host has its own identity under the dedicated Incus CA.
resource "tls_private_key" "incus_client" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"

  lifecycle {
    prevent_destroy = true
  }
}

resource "tls_cert_request" "incus_client" {
  private_key_pem = tls_private_key.incus_client.private_key_pem

  subject {
    common_name  = "incus-client-${var.name}"
    organization = "Yinfeng"
  }
}

resource "tls_locally_signed_cert" "incus_client" {
  cert_request_pem   = tls_cert_request.incus_client.cert_request_pem
  ca_private_key_pem = var.incus_ca_private_key_pem
  ca_cert_pem        = var.incus_ca_cert_pem

  validity_period_hours = 2160 # 90 days
  early_renewal_hours   = 720  # 30 days
  allowed_uses          = ["client_auth"]
}

output "incus_client_private_key_pem" {
  value     = tls_private_key.incus_client.private_key_pem
  sensitive = true
}

output "incus_client_cert_pem" {
  value = tls_locally_signed_cert.incus_client.cert_pem
}

output "incus_client_cert_chain_pem" {
  value = "${trimspace(tls_locally_signed_cert.incus_client.cert_pem)}\n${trimspace(var.incus_ca_cert_pem)}\n"
}
