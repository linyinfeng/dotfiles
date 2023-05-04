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

resource "cloudflare_record" "zerotier_records" {
  for_each = zerotier_member.host.ip_assignments
  name    = "${var.name}.zt"
  ttl     = 1 # default ttl
  proxied = false
  type    = "A"
  value   = each.value
  zone_id = var.cloudflare_zone_id
}
