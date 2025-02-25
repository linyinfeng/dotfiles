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

resource "hcloud_server" "fsn0" {
  name               = "fsn0"
  server_type        = "cax31"
  datacenter         = "fsn1-dc14"
  image              = "debian-11"
  delete_protection  = true
  rebuild_protection = true
  ssh_keys           = [hcloud_ssh_key.pgp.id]
  public_net {
    ipv4 = hcloud_primary_ip.fsn0_ipv4.id
    ipv6 = hcloud_primary_ip.fsn0_ipv6.id
  }
  lifecycle {
    ignore_changes = [ssh_keys]
  }
}

resource "hcloud_primary_ip" "fsn0_ipv4" {
  name              = "fsn0-v4"
  type              = "ipv4"
  datacenter        = "fsn1-dc14"
  assignee_type     = "server"
  auto_delete       = false
  delete_protection = true
}

resource "hcloud_primary_ip" "fsn0_ipv6" {
  name              = "fsn0-v6"
  type              = "ipv6"
  datacenter        = "fsn1-dc14"
  assignee_type     = "server"
  auto_delete       = false
  delete_protection = true
}

output "fsn0_ipv6_address" {
  value     = hcloud_server.fsn0.ipv6_address
  sensitive = true
}

output "fsn0_ipv6_prefix" {
  value     = split("/", hcloud_server.fsn0.ipv6_network)[0]
  sensitive = true
}

output "fsn0_ipv6_prefix_length" {
  value     = split("/", hcloud_server.fsn0.ipv6_network)[1]
  sensitive = true
}

resource "hcloud_rdns" "fsn0_ipv4" {
  server_id  = hcloud_server.fsn0.id
  ip_address = hcloud_server.fsn0.ipv4_address
  dns_ptr    = "smtp.li7g.com"
}

resource "hcloud_rdns" "fsn0_ipv6" {
  server_id  = hcloud_server.fsn0.id
  ip_address = hcloud_server.fsn0.ipv6_address
  dns_ptr    = "smtp.li7g.com"
}
