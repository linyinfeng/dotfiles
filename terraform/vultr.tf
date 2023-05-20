provider "vultr" {
  api_key     = data.sops_file.terraform.data["vultr.api-key"]
  rate_limit  = 700
  retry_limit = 2
}

resource "vultr_instance" "mia0" {
  plan   = "vc2-1c-0.5gb" # actually an invalid plan
  region = "mia"

  lifecycle {
    ignore_changes = [
      # this plan already removed by vultr
      plan
    ]
  }
}

resource "vultr_ssh_key" "pgp" {
  name    = "pgp"
  ssh_key = trim(file("${path.module}/../nixos/profiles/users/root/_ssh/pgp.pub"), "\n ")
}
