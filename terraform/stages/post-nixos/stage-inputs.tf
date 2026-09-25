# Stage interface: pre-nixos publishes these through its encrypted outputs file.

variable "terraform_input_path" {
  type = string
}

variable "pre_nixos_outputs_path" {
  type = string
}

data "sops_file" "terraform" {
  source_file = var.terraform_input_path
}

data "sops_file" "pre_nixos" {
  source_file = var.pre_nixos_outputs_path
}

locals {
  pre_nixos          = yamldecode(data.sops_file.pre_nixos.raw)
  garage_admin_token = local.pre_nixos.garage_admin_token.value
  garage_keys        = jsondecode(local.pre_nixos.garage_keys_json.value)
  # must stay non-sensitive: sensitive values cannot be for_each keys
  garage_backup_hosts = nonsensitive(jsondecode(local.pre_nixos.garage_backup_hosts_json.value))
  # non-sensitive on purpose: device names are public
  tailscale_hosts      = nonsensitive(jsondecode(local.pre_nixos.tailscale_hosts_json.value))
  cloudflare_zone_id   = nonsensitive(local.pre_nixos.cloudflare_com_li7g_zone_id.value)
  cloudflare_zone_name = nonsensitive(local.pre_nixos.cloudflare_com_li7g_zone_name.value)
}
