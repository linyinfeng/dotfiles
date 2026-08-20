provider "hcloud" {
  token = data.sops_file.terraform.data["hcloud.token"]
}

resource "hcloud_ssh_key" "pgp" {
  name       = "PGP"
  public_key = file("${path.module}/../nixos/profiles/users/root/_ssh/pgp.pub")
}

data "hcloud_locations" "all" {
}

data "hcloud_datacenters" "all" {
}
