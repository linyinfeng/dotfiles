variable "dn42_host_indices" {
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
  dn42_v4_addresses     = [for i in var.dn42_host_indices : cidrhost(var.dn42_v4_cidr, i)]
  dn42_v6_prefixes      = [for i in var.dn42_host_indices : cidrsubnet(var.dn42_v6_cidr, 64 - local.dn42_v6_prefix_length, i)]
  dn42_v6_addresses     = [for p in local.dn42_v6_prefixes : cidrhost(p, 1)]
}
output "dn42_host_indices" {
  value = var.dn42_host_indices
}
output "dn42_v4_addresses" {
  value = local.dn42_v4_addresses
}
output "dn42_v6_prefixes" {
  value = local.dn42_v6_prefixes
}
output "dn42_v6_addresses" {
  value = local.dn42_v6_addresses
}