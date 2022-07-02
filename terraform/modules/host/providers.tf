terraform {
  required_providers {
    # official verified providers
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
    zerotier = {
      source = "zerotier/zerotier"
    }
    # third-party providers
    wireguard = {
      source = "OJFord/wireguard"
    }
  }
}
