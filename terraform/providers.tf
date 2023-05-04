terraform {
  required_providers {
    # official verified providers
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
    vultr = {
      source = "vultr/vultr"
    }
    tencentcloud = {
      source = "tencentcloudstack/tencentcloud"
    }
    zerotier = {
      source = "zerotier/zerotier"
    }
    b2 = {
      source = "Backblaze/b2"
    }
    oci = {
      source = "oracle/oci"
    }
    hcloud = {
      source = "hetznercloud/hcloud"
    }
    tailscale = {
      source = "tailscale/tailscale"
    }
    grafana = {
      source = "grafana/grafana"
    }
    null = {
      source = "hashicorp/null"
    }
    # third-party providers
    sops = {
      source = "carlpett/sops"
    }
    minio = {
      source = "aminueza/minio"
    }
    shell = {
      source = "linyinfeng/shell"
    }
    htpasswd = {
      source = "loafoe/htpasswd"
    }
  }
}
