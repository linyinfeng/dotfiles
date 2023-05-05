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
variable "wireguard_dn42_min" {
  type    = number
  default = 20000
}
variable "wireguard_dn42_self" {
  type    = number
  default = 20128
}
variable "wireguard_dn42_max" {
  type    = number
  default = 23999
}
output "wireguard_dn42_min" {
  value     = var.wireguard_dn42_min
  sensitive = false
}
output "wireguard_dn42_self" {
  value     = var.wireguard_dn42_self
  sensitive = false
}
output "wireguard_dn42_max" {
  value     = var.wireguard_dn42_max
  sensitive = false
}
