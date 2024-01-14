variable "dn42_v4_cidr" {
  default = "172.23.224.96/27"
  type    = string
}
variable "dn42_v6_cidr" {
  default = "fd72:db83:badd::/48"
  type    = string
}
output "dn42_v4_cidr" {
  value     = var.dn42_v4_cidr
  sensitive = false
}
output "dn42_v6_cidr" {
  value     = var.dn42_v6_cidr
  sensitive = false
}

variable "dn42_anycast_v6_cidr" {
  default = "fd72:db83:badd:ffff::/64" # last /64
  type    = string
}
output "dn42_anycast_v6_cidr" {
  value     = var.dn42_anycast_v6_cidr
  sensitive = false
}
locals {
  dn42_anycast_dns_v6 = "fd72:db83:badd:ffff::8888"
}
output "dn42_anycast_dns_v6" {
  value     = local.dn42_anycast_dns_v6
  sensitive = false
}
