# Provision online issuing keys independently of the offline signer and services.
# The root private key must never enter this stage.
locals {
  intermediate_ca_profiles = {
    mesh-v1     = "Yinfeng Mesh Intermediate CA v1"
    services-v1 = "Yinfeng Services Intermediate CA v1"
  }
}

resource "tls_private_key" "intermediate_ca" {
  for_each = local.intermediate_ca_profiles

  algorithm   = "ECDSA"
  ecdsa_curve = "P384"

  lifecycle {
    prevent_destroy = true
  }
}

resource "tls_cert_request" "intermediate_ca" {
  for_each = local.intermediate_ca_profiles

  private_key_pem = tls_private_key.intermediate_ca[each.key].private_key_pem

  subject {
    common_name  = each.value
    organization = "Yinfeng"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# These are public enrollment requests, not CA certificates. The offline signer
# reviews each request and enforces its own CA constraints and lifetime.
output "intermediate_ca_requests" {
  value = {
    for name, request in tls_cert_request.intermediate_ca : name => request.cert_request_pem
  }
}

# Only online issuing keys are shared with the stage that signs leaf certificates.
# SOPS encrypts this sensitive output for personal PGP keys and the CI age key.
output "intermediate_ca_private_keys" {
  value = {
    for name, key in tls_private_key.intermediate_ca : name => key.private_key_pem
  }
  sensitive = true
}
