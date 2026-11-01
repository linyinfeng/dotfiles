variable "root_ca_outputs_path" {
  type = string
}

variable "intermediate_ca_outputs_path" {
  type = string
}

# This file contains only public certificate metadata, never the root private key.
data "sops_file" "root_ca" {
  source_file = var.root_ca_outputs_path
}

data "sops_file" "intermediate_ca" {
  source_file = var.intermediate_ca_outputs_path
}

locals {
  root_ca_outputs                     = yamldecode(data.sops_file.root_ca.raw)
  root_ca_cert_pem                    = nonsensitive(local.root_ca_outputs.root_ca_cert_pem.value)
  signed_intermediate_ca_certificates = nonsensitive(local.root_ca_outputs.intermediate_ca_certificates.value)

  intermediate_ca_generations = {
    mesh     = "mesh-v1"
    services = "services-v1"
  }

  intermediate_ca_outputs = yamldecode(data.sops_file.intermediate_ca.raw)
  intermediate_ca_requests = nonsensitive(
    local.intermediate_ca_outputs.intermediate_ca_requests.value
  )
  intermediate_ca_private_keys = local.intermediate_ca_outputs.intermediate_ca_private_keys.value

  ca_issuers = {
    for purpose, generation in local.intermediate_ca_generations : purpose => {
      cert_pem        = local.signed_intermediate_ca_certificates[generation].cert_pem
      private_key_pem = local.intermediate_ca_private_keys[generation]
    }
  }
}

check "intermediate_ca_names" {
  assert {
    condition = toset(keys(local.intermediate_ca_requests)) == toset(keys(local.signed_intermediate_ca_certificates))
    error_message = format(
      "Intermediate CA enrollment and signed certificate names differ. Unsigned requests: [%s]; certificates without requests: [%s]. Review intermediate-ca and root-ca; differences may be intentional during rotation.",
      join(", ", setsubtract(toset(keys(local.intermediate_ca_requests)), toset(keys(local.signed_intermediate_ca_certificates)))),
      join(", ", setsubtract(toset(keys(local.signed_intermediate_ca_certificates)), toset(keys(local.intermediate_ca_requests))))
    )
  }

  assert {
    condition = toset(values(local.intermediate_ca_generations)) == toset(keys(local.signed_intermediate_ca_certificates))
    error_message = format(
      "Intermediate CA signing and issuer selection names differ. Unselected certificates: [%s]; selected generations without certificates: [%s]. Review root-ca and pre-nixos; differences may be intentional during rotation.",
      join(", ", setsubtract(toset(keys(local.signed_intermediate_ca_certificates)), toset(values(local.intermediate_ca_generations)))),
      join(", ", setsubtract(toset(values(local.intermediate_ca_generations)), toset(keys(local.signed_intermediate_ca_certificates))))
    )
  }
}

output "intermediate_ca_generations" {
  value = local.intermediate_ca_generations

  precondition {
    condition = alltrue([
      for purpose, generation in local.intermediate_ca_generations :
      startswith(generation, "${purpose}-")
    ])
    error_message = "Each issuer must select a generation for its own purpose."
  }

  precondition {
    condition = alltrue([
      for generation in values(local.intermediate_ca_generations) : try(
        local.signed_intermediate_ca_certificates[generation].csr_sha256 == sha256(local.intermediate_ca_requests[generation]),
        false
      )
    ])
    error_message = "An intermediate has no matching root-signed CSR; sign the current request in root-ca first."
  }

  precondition {
    condition = alltrue([
      for generation in values(local.intermediate_ca_generations) : try(
        timecmp(local.signed_intermediate_ca_certificates[generation].validity_end_time, timeadd(plantimestamp(), "2160h")) >= 0,
        false
      )
    ])
    error_message = "An intermediate expires before a full 90-day leaf certificate lifetime; renew it in root-ca first."
  }
}

output "root_ca_cert_pem" {
  value = local.root_ca_cert_pem
}

output "intermediate_ca_certificates" {
  value = {
    for name, certificate in local.signed_intermediate_ca_certificates : name => certificate.cert_pem
  }
}
