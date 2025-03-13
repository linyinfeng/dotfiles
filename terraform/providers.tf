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
    alicloud = {
      source = "aliyun/alicloud"
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
    google = {
      source = "hashicorp/google"
    }
    google-beta = {
      source = "hashicorp/google-beta"
    }
    gitlab = {
      source = "gitlabhq/gitlab"
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
    assert = {
      source = "bwoznicki/assert"
    }
    acme = {
      source = "vancluever/acme"
    }
  }
}
