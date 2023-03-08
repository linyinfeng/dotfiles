provider "hcloud" {
  token = data.sops_file.terraform.data["hcloud.token"]
}

resource "hcloud_firewall" "main" {
  name = "main"

  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

data "hcloud_locations" "all_locations" {
}

data "hcloud_datacenters" "all_datacenters" {
}

variable "hclouod_datacenter" {
  type    = string
  default = "hil-dc1"
}

resource "hcloud_server" "hil0" {
  name               = "hil0"
  server_type        = "cpx31"
  datacenter         = var.hclouod_datacenter
  image              = "debian-11"
  delete_protection  = true
  rebuild_protection = true
  firewall_ids       = [hcloud_firewall.main.id]
  public_net {
    ipv4 = hcloud_primary_ip.hil0_ipv4.id
    ipv6 = hcloud_primary_ip.hil0_ipv6.id
  }
}

resource "hcloud_primary_ip" "hil0_ipv4" {
  name              = "hil0-v4"
  type              = "ipv4"
  datacenter        = var.hclouod_datacenter
  assignee_type     = "server"
  auto_delete       = false
  delete_protection = true
}

resource "hcloud_primary_ip" "hil0_ipv6" {
  name              = "hil0-v6"
  type              = "ipv6"
  datacenter        = var.hclouod_datacenter
  assignee_type     = "server"
  auto_delete       = false
  delete_protection = true
}

resource "hcloud_rdns" "hil0_ipv4" {
  server_id  = hcloud_server.hil0.id
  ip_address = hcloud_server.hil0.ipv4_address
  dns_ptr    = "smtp.li7g.com"
}

resource "hcloud_rdns" "hil0_ipv6" {
  server_id  = hcloud_server.hil0.id
  ip_address = hcloud_server.hil0.ipv6_address
  dns_ptr    = "smtp.li7g.com"
}

output "hil0_ipv6_address" {
  value     = hcloud_server.hil0.ipv6_address
  sensitive = true
}

output "hil0_ipv6_prefix" {
  value     = split("/", hcloud_server.hil0.ipv6_network)[0]
  sensitive = true
}

output "hil0_ipv6_prefix_length" {
  value     = split("/", hcloud_server.hil0.ipv6_network)[1]
  sensitive = true
}
