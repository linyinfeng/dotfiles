# just output endpoints
variable "endpoints_v4" {
  type = list(string)
}
variable "endpoints_v6" {
  type = list(string)
}
locals {
  has_endpoints_v4 = length(var.endpoints_v4) != 0
  has_endpoints_v6 = length(var.endpoints_v6) != 0
  has_endpoints    = local.has_endpoints_v4 || local.has_endpoints_v6
}
output "endpoints" {
  value     = concat(var.endpoints_v4, var.endpoints_v6)
  sensitive = false
}
output "endpoints_v4" {
  value     = var.endpoints_v4
  sensitive = false
}
output "endpoints_v6" {
  value     = var.endpoints_v6
  sensitive = false
}
