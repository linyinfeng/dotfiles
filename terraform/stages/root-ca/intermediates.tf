variable "intermediate_ca_outputs_path" {
  type = string
}

data "sops_file" "intermediate_ca" {
  source_file = var.intermediate_ca_outputs_path
}

locals {
  # Signing is a local, manual operation. Review these requests and the plan
  # before applying; requests outside this configured set are never signed.
  intermediate_ca_names = toset(["mesh-v1", "services-v1"])
  intermediate_ca_requests = nonsensitive(
    yamldecode(data.sops_file.intermediate_ca.raw).intermediate_ca_requests.value
  )
}

resource "tls_locally_signed_cert" "intermediate_ca" {
  for_each = local.intermediate_ca_names

  cert_request_pem   = local.intermediate_ca_requests[each.key]
  ca_private_key_pem = tls_private_key.root_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.root_ca.cert_pem

  validity_period_hours = 5 * 365 * 24
  early_renewal_hours   = 0
  is_ca_certificate     = true
  # TODO wait for https://github.com/hashicorp/terraform-provider-tls/pull/828
  max_path_length    = 0
  set_subject_key_id = true
  allowed_uses       = ["cert_signing", "crl_signing"]

  lifecycle {
    prevent_destroy = true
  }
}

output "intermediate_ca_certificates" {
  value = {
    for name, certificate in tls_locally_signed_cert.intermediate_ca : name => {
      cert_pem          = certificate.cert_pem
      validity_end_time = certificate.validity_end_time
      csr_sha256        = sha256(local.intermediate_ca_requests[name])
    }
  }
}
