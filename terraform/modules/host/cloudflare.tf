variable "cloudflare_zone_id" {
    type = string
}

variable "records" {
    type = list(object({
        proxied = bool
        type    = string
        value   = string
    }))
}

variable "ddns_records" {
    type = list(object({
        proxied = bool
        type    = string
        value   = string
    }))
}

resource "cloudflare_record" "record" {
  name    = var.name
  for_each = { for index, r in var.records: index => r }
  ttl     = 1 # default ttl
  proxied = each.value.proxied
  type = each.value.type
  value = each.value.value
  zone_id = var.cloudflare_zone_id
}

resource "cloudflare_record" "ddns_record" {
  name    = var.name
  for_each = { for index, r in var.ddns_records: index => r }
  ttl     = 1 # default ttl
  proxied = each.value.proxied
  type = each.value.type
  value = each.value.value
  zone_id = var.cloudflare_zone_id
  lifecycle { ignore_changes = [value] }
}
