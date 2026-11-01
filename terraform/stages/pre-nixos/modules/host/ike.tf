variable "ike_ca_private_key_pem" {
  type      = string
  sensitive = true
}
variable "ike_ca_cert_pem" {
  type = string
}
resource "tls_private_key" "ike" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}
resource "tls_cert_request" "ike" {
  private_key_pem = tls_private_key.ike.private_key_pem
  dns_names       = ["${var.name}.li7g.com"]
  subject {
    common_name  = "${var.name}.li7g.com"
    organization = "Yinfeng"
  }
}
resource "tls_locally_signed_cert" "ike" {
  cert_request_pem   = tls_cert_request.ike.cert_request_pem
  ca_private_key_pem = var.ike_ca_private_key_pem
  ca_cert_pem        = var.ike_ca_cert_pem

  validity_period_hours = 2160 # 90 days
  early_renewal_hours   = 720  # 30 days
  allowed_uses = [
    "server_auth"
  ]
}
output "ike_private_key_pem" {
  value     = tls_private_key.ike.private_key_pem
  sensitive = true
}
output "ike_cert_pem" {
  value     = tls_locally_signed_cert.ike.cert_pem
  sensitive = false
}
