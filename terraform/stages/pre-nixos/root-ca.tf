variable "root_ca_outputs_path" {
  type = string
}

# This file contains only public certificate metadata, never the root private key.
data "sops_file" "root_ca" {
  source_file = var.root_ca_outputs_path
}

output "root_ca_cert_pem" {
  value = nonsensitive(yamldecode(data.sops_file.root_ca.raw).root_ca_cert_pem.value)
}
