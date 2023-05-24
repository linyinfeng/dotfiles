variable "host_indices" {
  type = list(number)
}
variable "dn42_v4_cidr" {
  type = string
}
variable "dn42_v6_cidr" {
  type = string
}
locals {
  dn42_v4_prefix_length = tonumber(regex(".*/([[:digit:]]+)", var.dn42_v4_cidr)[0])
  dn42_v6_prefix_length = tonumber(regex(".*/([[:digit:]]+)", var.dn42_v6_cidr)[0])
  dn42_addresses_v4     = [for i in var.host_indices : cidrhost(var.dn42_v4_cidr, i)]
  dn42_v6_prefixes      = [for i in var.host_indices : cidrsubnet(var.dn42_v6_cidr, 64 - local.dn42_v6_prefix_length, i)]
  dn42_addresses_v6     = [for p in local.dn42_v6_prefixes : cidrhost(p, 1)]
}
output "host_indices" {
  value = var.host_indices
}
output "dn42_addresses_v4" {
  value = local.dn42_addresses_v4
}
output "dn42_v6_prefixes" {
  value = local.dn42_v6_prefixes
}
output "dn42_addresses_v6" {
  value = local.dn42_addresses_v6
}
