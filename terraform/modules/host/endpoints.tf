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
  value     = local.has_endpoints ? ["${var.name}.endpoints.li7g.com"] : []
  sensitive = false
}
output "endpoints_v4" {
  value     = local.has_endpoints_v4 ? ["v4.${var.name}.endpoints.li7g.com"] : []
  sensitive = false
}
output "endpoints_v6" {
  value     = local.has_endpoints_v6 ? ["v6.${var.name}.endpoints.li7g.com"] : []
  sensitive = false
}
