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
