terraform {
  required_providers {
    # official verified providers
    cloudflare = {
      source = "cloudflare/cloudflare"
      # keep in sync with the pre-nixos stage pin
      version = "5.22.0"
    }
    tailscale = {
      source = "tailscale/tailscale"
    }
    # third-party providers
    sops = {
      source = "carlpett/sops"
    }
    garage = {
      source = "jkossis/garage"
    }
  }
}
