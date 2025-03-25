variable "cloudflare_zone_id" {
  type = string
}
variable "cloudflare_zone_name" {
  type = string
}
variable "records" {
  type = map(object({
    proxied = bool
    type    = string
    value   = string
  }))
}

variable "ddns_records" {
  type = map(object({
    proxied = bool
    type    = string
    value   = string
  }))
}

resource "cloudflare_dns_record" "records" {
  name     = "${var.name}.${var.cloudflare_zone_name}"
  for_each = var.records
  ttl      = 1 # default ttl
  proxied  = each.value.proxied
  type     = each.value.type
  content  = each.value.value
  zone_id  = var.cloudflare_zone_id
}
resource "cloudflare_dns_record" "ddns_records" {
  name     = "${var.name}.${var.cloudflare_zone_name}"
  for_each = var.ddns_records
  ttl      = 1 # default ttl
  proxied  = each.value.proxied
  type     = each.value.type
  content  = each.value.value
  zone_id  = var.cloudflare_zone_id
  lifecycle { ignore_changes = [content] }
}
resource "cloudflare_dns_record" "zerotier" {
  for_each = toset(flatten([for h in zerotier_member.host : [for a in h.ip_assignments : a if length(regexall("[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+", a)) > 0]]))
  name     = "${var.name}.zt.${var.cloudflare_zone_name}"
  ttl      = 1 # default ttl
  proxied  = false
  type     = "A"
  content  = each.value
  zone_id  = var.cloudflare_zone_id
}
resource "cloudflare_dns_record" "enpoint_v4_only_records" {
  name     = "v4.${var.name}.endpoints.${var.cloudflare_zone_name}"
  for_each = toset(var.endpoints_v4)
  ttl      = 1 # default ttl
  proxied  = false
  type     = "A"
  content  = each.value
  zone_id  = var.cloudflare_zone_id
}
resource "cloudflare_dns_record" "enpoint_v4_records" {
  name     = "${var.name}.endpoints.${var.cloudflare_zone_name}"
  for_each = toset(var.endpoints_v4)
  ttl      = 1 # default ttl
  proxied  = false
  type     = "A"
  content  = each.value
  zone_id  = var.cloudflare_zone_id
}
resource "cloudflare_dns_record" "enpoint_v6_only_records" {
  name     = "v6.${var.name}.endpoints.${var.cloudflare_zone_name}"
  for_each = toset(var.endpoints_v6)
  ttl      = 1 # default ttl
  proxied  = false
  type     = "AAAA"
  content  = each.value
  zone_id  = var.cloudflare_zone_id
}
resource "cloudflare_dns_record" "enpoint_v6_records" {
  name     = "${var.name}.endpoints.${var.cloudflare_zone_name}"
  for_each = toset(var.endpoints_v6)
  ttl      = 1 # default ttl
  proxied  = false
  type     = "AAAA"
  content  = each.value
  zone_id  = var.cloudflare_zone_id
}

resource "cloudflare_dns_record" "dn42_v4_records" {
  name     = "${var.name}.dn42.${var.cloudflare_zone_name}"
  for_each = toset(local.dn42_addresses_v4)
  ttl      = 1 # default ttl
  proxied  = false
  type     = "A"
  content  = each.value
  zone_id  = var.cloudflare_zone_id
}

resource "cloudflare_dns_record" "dn42_v6_records" {
  name     = "${var.name}.dn42.${var.cloudflare_zone_name}"
  for_each = toset(local.dn42_addresses_v6)
  ttl      = 1 # default ttl
  proxied  = false
  type     = "AAAA"
  content  = each.value
  zone_id  = var.cloudflare_zone_id
}
