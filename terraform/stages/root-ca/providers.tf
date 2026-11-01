terraform {
  required_providers {
    tls = {
      source = "hashicorp/tls"
    }
    sops = {
      source = "carlpett/sops"
    }
  }
}
