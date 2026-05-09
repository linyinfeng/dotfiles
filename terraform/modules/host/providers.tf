terraform {
  required_providers {
    # official verified providers
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
    zerotier = {
      source = "zerotier/zerotier"
    }
    b2 = {
      source = "Backblaze/b2"
    }
    # third-party providers
    wireguard = {
      source = "OJFord/wireguard"
    }
    garage = {
      source = "jkossis/garage"
    }
    shell = {
      source = "linyinfeng/shell"
    }
  }
}
