provider "zerotier" {
  zerotier_central_token = data.sops_file.terraform.data["zerotier.central-token"]
}

locals {
  zerotier_main_subnet                 = "172.29.0.0"
  zerotier_main_subnet_cidr            = "${local.zerotier_main_subnet}/${local.zerotier_main_subnet_bits}"
  zerotier_main_subnet_bits            = 16
  zerotier_main_subnet_min_host_number = 1
  zerotier_main_subnet_max_host_number = pow(2, local.zerotier_main_subnet_bits) - 2
}

resource "zerotier_network" "main" {
  name = "main"

  assign_ipv4 {
    zerotier = true
  }
  assign_ipv6 {
    zerotier = false
    sixplane = false
    rfc4193  = false
  }
  assignment_pool {
    start = cidrhost(local.zerotier_main_subnet_cidr, local.zerotier_main_subnet_min_host_number)
    end   = cidrhost(local.zerotier_main_subnet_cidr, local.zerotier_main_subnet_max_host_number)
  }
  route {
    target = local.zerotier_main_subnet_cidr
  }

  enable_broadcast = true
  private          = true
  flow_rules       = <<EOF
# # allow only IPv4, IPv4 ARP, and IPv6 Ethernet frames.
# drop
#   not ethertype ipv4
#   and not ethertype arp
#   and not ethertype ipv6
# ;
# accept anything else
accept;
EOF
}

output "zerotier_network_id" {
  value     = zerotier_network.main.id
  sensitive = true
}

variable "zerotier_moon_main_host" {
  type    = string
  default = "hkg0"
}
variable "zerotier_port" {
  type    = number
  default = 9993
}
locals {
  zerotier_moon_id = module.hosts[var.zerotier_moon_main_host].zerotier_id
  zerotier_moon_hosts = [
    for host in keys(local.hosts) : host
    if length(local.hosts[host].records) > 0
  ]
}

resource "shell_sensitive_script" "init_moon" {
  lifecycle_commands {
    create = <<EOT
      set -e

      PUBLIC_KEY_FILE=$(mktemp -t zerotier-init-moon-public-key.XXXXXXXXXX)
      echo "$ZEROTIER_MAIN_HOST_PUBLIC_KEY" > "$PUBLIC_KEY_FILE"
      cleanup() {
        rm "$PUBLIC_KEY_FILE"
      }
      trap cleanup EXIT
      zerotier-idtool initmoon "$PUBLIC_KEY_FILE"
    EOT
    delete = <<EOT
      # do nothing
    EOT
  }
  environment = {
    ZEROTIER_MAIN_HOST_PUBLIC_KEY = module.hosts[var.zerotier_moon_main_host].zerotier_public_key
  }
}
locals {
  zerotier_moon_json_original = shell_sensitive_script.init_moon.output
  zerotier_moon_json = merge(local.zerotier_moon_json_original, {
    roots = [
      for host in local.zerotier_moon_hosts :
      {
        identity = module.hosts[host].zerotier_public_key
        stableEndpoints = [
          for k, v in local.hosts[host].records :
          "${v.value}/${var.zerotier_port}"
          if v.type == "A" || v.type == "AAAA"
        ]
      }
    ]
  })
  zerotier_moon_json_string = jsonencode(local.zerotier_moon_json)
}
output "zerotier_moon_json" {
  value     = local.zerotier_moon_json_string
  sensitive = true
}
resource "shell_sensitive_script" "generate_moon" {
  lifecycle_commands {
    create = <<EOT
      set -e

      TMP_DIR=$(mktemp -t --directory zerotier-generate-moon.XXXXXXXXXX)
      cleanup() {
        rm -r "$TMP_DIR"
      }
      trap cleanup EXIT

      pushd "$TMP_DIR" > /dev/null
      echo "$ZEROTIER_MOON_JSON" > moon.json
      zerotier-idtool genmoon moon.json
      MOON_FILENAME=$(ls *.moon)

      jq --null-input \
        --arg filename "$MOON_FILENAME" \
        --arg content_base64 "$(cat "$MOON_FILENAME" | base64 --wrap=0)" \
        '{"filename": $filename, "content_base64": $content_base64}'

      popd > /dev/null
    EOT
    delete = <<EOT
      # do nothing
    EOT
  }
  sensitive_environment = {
    ZEROTIER_MOON_JSON = local.zerotier_moon_json_string
  }
}
output "zerotier_moon" {
  value     = shell_sensitive_script.generate_moon.output
  sensitive = true
}
