terraform {
  required_providers {
    incus = {
      source = "lxc/incus"
    }
  }
}

# Home Manager supplies the remote, pinned server certificate and host identity.
# Use mTLS so unattended operations do not require an interactive OIDC login.
provider "incus" {
  default_remote               = "ostrich-mtls"
  generate_client_certificates = false
  accept_remote_certificate    = false

  remote {
    name = "ostrich-mtls"
  }
}
