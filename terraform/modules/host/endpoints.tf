# just output endpoints
variable "endpoints_v4" {
  type = list(string)
}
variable "endpoints_v6" {
  type = list(string)
}
output "endpoints_v4" {
  value     = var.endpoints_v4
  sensitive = false
}
output "endpoints_v6" {
  value     = var.endpoints_v6
  sensitive = false
}
