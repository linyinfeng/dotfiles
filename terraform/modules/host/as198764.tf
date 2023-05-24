variable "as198764_v6_cidr" {
  type = string
}
locals {
  as198764_addresses_v6 = [for i in var.host_indices : cidrhost(var.as198764_v6_cidr, i)]
}
output "as198764_addresses_v6" {
  value = local.as198764_addresses_v6
}
