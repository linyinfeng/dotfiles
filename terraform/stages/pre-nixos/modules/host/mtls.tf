variable "mtls_ca_private_key_pem" {
  type      = string
  sensitive = true
}

variable "mtls_ca_cert_pem" {
  type = string
}

variable "mtls_extra_dns_names" {
  type    = list(string)
  default = []
}
resource "tls_private_key" "mtls" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}
resource "tls_cert_request" "mtls" {
  private_key_pem = tls_private_key.mtls.private_key_pem
  dns_names       = concat(["${var.name}.li7g.com"], var.mtls_extra_dns_names)
  subject {
    common_name  = "${var.name}.li7g.com"
    organization = "Yinfeng"
  }
}
resource "tls_locally_signed_cert" "mtls" {
  cert_request_pem   = tls_cert_request.mtls.cert_request_pem
  ca_private_key_pem = var.mtls_ca_private_key_pem
  ca_cert_pem        = var.mtls_ca_cert_pem

  validity_period_hours = 2160 # 90 days
  early_renewal_hours   = 720  # 30 days
  allowed_uses = [
    # gRPC server of the hydra queue runner
    "server_auth",
    # gRPC client of the hydra build agent
    "client_auth",
  ]
}
output "mtls_private_key_pem" {
  value     = tls_private_key.mtls.private_key_pem
  sensitive = true
}
output "mtls_cert_pem" {
  value     = tls_locally_signed_cert.mtls.cert_pem
  sensitive = false
}
output "mtls_cert_chain_pem" {
  value = "${trimspace(tls_locally_signed_cert.mtls.cert_pem)}\n${trimspace(var.mtls_ca_cert_pem)}\n"
}
