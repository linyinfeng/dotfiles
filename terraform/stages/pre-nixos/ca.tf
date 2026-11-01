variable "root_ca_outputs_path" {
  type = string
}

# This file contains only public certificate metadata, never the root private key.
data "sops_file" "root_ca" {
  source_file = var.root_ca_outputs_path
}

locals {
  root_ca_outputs                     = yamldecode(data.sops_file.root_ca.raw)
  root_ca_cert_pem                    = nonsensitive(local.root_ca_outputs.root_ca_cert_pem.value)
  signed_intermediate_ca_certificates = nonsensitive(local.root_ca_outputs.intermediate_ca_certificates.value)
}

output "root_ca_cert_pem" {
  value = local.root_ca_cert_pem
}

output "mesh_intermediate_ca_certificates" {
  value = {
    for name, certificate in local.signed_intermediate_ca_certificates : name => certificate.cert_pem
    if startswith(name, "mesh-")
  }
}
