variable "as198764_v6_cidr" {
  type    = string
  default = "2a0c:b641:a11:badd::/64"
}
variable "as198764_anycast_address" {
  type    = string
  default = "2a0c:b641:a11:badd::1:1"
}
output "as198764_v6_cidr" {
  value = var.as198764_v6_cidr
}
output "as198764_anycast_address" {
  value = var.as198764_anycast_address
}
