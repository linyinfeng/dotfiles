variable "cloudflare_zone_id" {
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

resource "cloudflare_record" "records" {
  name     = var.name
  for_each = var.records
  ttl      = 1 # default ttl
  proxied  = each.value.proxied
  type     = each.value.type
  value    = each.value.value
  zone_id  = var.cloudflare_zone_id
}
resource "cloudflare_record" "ddns_records" {
  name     = var.name
  for_each = var.ddns_records
  ttl      = 1 # default ttl
  proxied  = each.value.proxied
  type     = each.value.type
  value    = each.value.value
  zone_id  = var.cloudflare_zone_id
  lifecycle { ignore_changes = [value] }
}
resource "cloudflare_record" "zerotier" {
  name    = "${var.name}.zt"
  ttl     = 1 # default ttl
  proxied = false
  type    = "A"
  value   = tolist([for a in zerotier_member.host.ip_assignments : a if length(regexall("[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+", a)) > 0])[0]
  zone_id = var.cloudflare_zone_id
}
resource "cloudflare_record" "enpoint_v4_only_records" {
  name     = "v4.${var.name}.endpoints"
  for_each = toset(var.endpoints_v4)
  ttl      = 1 # default ttl
  proxied  = false
  type     = "A"
  value    = each.value
  zone_id  = var.cloudflare_zone_id
}
resource "cloudflare_record" "enpoint_v4_records" {
  name     = "${var.name}.endpoints"
  for_each = toset(var.endpoints_v4)
  ttl      = 1 # default ttl
  proxied  = false
  type     = "A"
  value    = each.value
  zone_id  = var.cloudflare_zone_id
}
resource "cloudflare_record" "enpoint_v6_only_records" {
  name     = "v6.${var.name}.endpoints"
  for_each = toset(var.endpoints_v6)
  ttl      = 1 # default ttl
  proxied  = false
  type     = "AAAA"
  value    = each.value
  zone_id  = var.cloudflare_zone_id
}
resource "cloudflare_record" "enpoint_v6_records" {
  name     = "${var.name}.endpoints"
  for_each = toset(var.endpoints_v6)
  ttl      = 1 # default ttl
  proxied  = false
  type     = "AAAA"
  value    = each.value
  zone_id  = var.cloudflare_zone_id
}

resource "cloudflare_record" "dn42_v4_records" {
  name     = "${var.name}.dn42"
  for_each = toset(local.dn42_addresses_v4)
  ttl      = 1 # default ttl
  proxied  = false
  type     = "A"
  value    = each.value
  zone_id  = var.cloudflare_zone_id
}

resource "cloudflare_record" "dn42_v6_records" {
  name     = "${var.name}.dn42"
  for_each = toset(local.dn42_addresses_v6)
  ttl      = 1 # default ttl
  proxied  = false
  type     = "AAAA"
  value    = each.value
  zone_id  = var.cloudflare_zone_id
}
