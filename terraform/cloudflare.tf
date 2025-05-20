provider "cloudflare" {
  api_token = data.sops_file.terraform.data["cloudflare.api-token"]
}

# -------------
# DDNS and ACME token

# TODO broken

data "cloudflare_api_token_permission_groups_list" "all" {
}

locals {
  used_permission_groups = [for group in data.cloudflare_api_token_permission_groups_list.all.result : group if contains([
    "Zone Settings Read",
    "Zone Read",
    "DNS Write",
    "Workers R2 Storage Bucket Item Write",
  ], group.name)]
  permissions_groups_map = { for group in local.used_permission_groups : group.name => group.id }
}

resource "cloudflare_api_token" "hosts" {
  name   = "hosts"
  status = "active"
  policies = [{
    effect = "allow"
    permission_groups = [
      { id = local.permissions_groups_map["Zone Settings Read"] },
      { id = local.permissions_groups_map["Zone Read"] },
      { id = local.permissions_groups_map["DNS Write"] },
    ]
    resources = {
      "com.cloudflare.api.account.zone.*" = "*"
    }
  }]
}

output "cloudflare_token" {
  value     = cloudflare_api_token.hosts.value
  sensitive = true
}

# -------------
# Account ID

locals {
  cloudflare_main_account_id = data.sops_file.terraform.data["cloudflare.account-id"]
}

# -------------
# Zones

resource "cloudflare_zone" "com_li7g" {
  name = "li7g.com"
  account = {
    id = local.cloudflare_main_account_id
  }
}

resource "cloudflare_zone" "zip_prebuilt" {
  account = {
    id = local.cloudflare_main_account_id
  }
  name = "prebuilt.zip"
}

resource "cloudflare_zone_setting" "com_li7g" {
  zone_id    = cloudflare_zone.com_li7g.id
  setting_id = "ssl"
  value      = "strict"
}

resource "cloudflare_zone_setting" "zip_prebuilt" {
  zone_id    = cloudflare_zone.zip_prebuilt.id
  setting_id = "ssl"
  value      = "strict"
}

# ttl = 1 for automatic

# CNAME records

resource "cloudflare_dns_record" "li7g_home" {
  name    = "home.${cloudflare_zone.com_li7g.name}"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  content = "ae370c7d335a.sn.mynetname.net"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_dns_record" "li7g" {
  name    = "li7g.com"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  content = "fsn0.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_dns_record" "zip_prebuilt" {
  name    = "prebuilt.zip"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  content = "prebuilt-zip.li7g.com"
  zone_id = cloudflare_zone.zip_prebuilt.id
}
resource "cloudflare_dns_record" "zip_prebuilt_wildcard" {
  name = "*.${cloudflare_zone.zip_prebuilt.name}"
  # cloudflare's edge ssl certificate
  # only covers second level of the domain
  proxied = false
  ttl     = 1
  type    = "CNAME"
  content = "prebuilt-zip.li7g.com"
  zone_id = cloudflare_zone.zip_prebuilt.id
}

locals {
  service_cname_mappings = {
    atuin          = { on = "hkg0", proxy = true }
    cache-overlay  = { on = "hkg0", proxy = true }
    nuc-proxy      = { on = "hkg0", proxy = true }
    hydra-proxy    = { on = "hkg0", proxy = true }
    sicp-tutorials = { on = "hkg0", proxy = true }
    tar            = { on = "lax0", proxy = true }
    pgp-public-key = { on = "lax0", proxy = true }
    oranc          = { on = "lax0", proxy = true }
    ace-bot        = { on = "lax0", proxy = true }
    hledger        = { on = "mtl0", proxy = true }
    vault          = { on = "mtl0", proxy = true }
    pb             = { on = "mtl0", proxy = true }
    git            = { on = "mtl0", proxy = true }
    box            = { on = "mtl0", proxy = true }
    minio-console  = { on = "mtl0", proxy = true }
    static         = { on = "mtl0", proxy = true }
    http-test      = { on = "mtl0", proxy = true }
    sicp-staging   = { on = "mtl0", proxy = true }
    portal         = { on = "hkg0", proxy = false }
    minio          = { on = "mtl0", proxy = false }
    prebuilt-zip   = { on = "mtl0", proxy = false }
    matrix         = { on = "fsn0", proxy = true }
    synapse-admin  = { on = "fsn0", proxy = true }
    social         = { on = "fsn0", proxy = true }
    mastodon       = { on = "fsn0", proxy = true }
    smtp           = { on = "fsn0", proxy = false }
    influxdb       = { on = "fsn0", proxy = true }
    bird-lg        = { on = "fsn0", proxy = true }
    dn42           = { on = "fsn0", proxy = true }
    keycloak       = { on = "fsn0", proxy = true }
    hydra          = { on = "nuc", proxy = false }
    transmission   = { on = "nuc", proxy = false }
    jellyfin       = { on = "nuc", proxy = false }
    nextcloud      = { on = "nuc", proxy = false }
    mc             = { on = "nuc", proxy = false }
    matrix-qq      = { on = "nuc", proxy = false }
    teamspeak      = { on = "nuc", proxy = false }
  }
}
output "service_cname_mappings" {
  value     = local.service_cname_mappings
  sensitive = false
}

resource "cloudflare_dns_record" "general_cname" {
  for_each = local.service_cname_mappings

  name    = "${each.key}.${cloudflare_zone.com_li7g.name}"
  proxied = each.value.proxy
  ttl     = 1
  type    = "CNAME"
  content = "${each.value.on}.${cloudflare_zone.com_li7g.name}"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_dns_record" "general_tailscale_cname" {
  for_each = local.service_cname_mappings

  name    = "${each.key}.ts.${cloudflare_zone.com_li7g.name}"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  content = "${each.value.on}.ts.${cloudflare_zone.com_li7g.name}"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_dns_record" "general_zerotier_cname" {
  for_each = local.service_cname_mappings

  name    = "${each.key}.zt.${cloudflare_zone.com_li7g.name}"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  content = "${each.value.on}.zt.${cloudflare_zone.com_li7g.name}"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_dns_record" "general_dn42_cname" {
  for_each = local.service_cname_mappings

  name    = "${each.key}.dn42.${cloudflare_zone.com_li7g.name}"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  content = "${each.value.on}.dn42.${cloudflare_zone.com_li7g.name}"
  zone_id = cloudflare_zone.com_li7g.id
}

# anycast record

resource "cloudflare_dns_record" "dns" {
  name    = "dns.${cloudflare_zone.com_li7g.name}"
  proxied = false
  ttl     = 1
  type    = "AAAA"
  content = local.dn42_anycast_dns_v6
  zone_id = cloudflare_zone.com_li7g.id
}

# localhost record

resource "cloudflare_dns_record" "localhost_a" {
  name    = "localhost.${cloudflare_zone.com_li7g.name}"
  proxied = false
  ttl     = 1
  type    = "A"
  content = "127.0.0.1"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_dns_record" "localhost_aaaa" {
  name    = "localhost.${cloudflare_zone.com_li7g.name}"
  proxied = false
  ttl     = 1
  type    = "AAAA"
  content = "::1"
  zone_id = cloudflare_zone.com_li7g.id
}

# ad-hoc ddns record

# currently nothing
# resource "cloudflare_dns_record" "mc" {
#   name    = "mc.${cloudflare_zone.com_li7g.name}"
#   proxied = false
#   ttl     = 1
#   type    = "A"
#   content   = "127.0.0.1"
#   zone_id = cloudflare_zone.com_li7g.id
#   lifecycle { ignore_changes = [content] }
# }

# smtp records for sending

resource "cloudflare_dns_record" "li7g_dkim" {
  name    = "default._domainkey.${cloudflare_zone.com_li7g.name}"
  proxied = false
  ttl     = 1
  type    = "TXT"
  content = "v=DKIM1; k=${local.dkim_algorithm}; p=${local.dkim_public_key}"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_dns_record" "li7g_dmarc" {
  name    = "_dmarc.${cloudflare_zone.com_li7g.name}"
  proxied = false
  ttl     = 1
  type    = "TXT"
  content = "v=DMARC1; p=quarantine; ruf=mailto:postmaster@li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_dns_record" "li7g_spf" {
  name    = cloudflare_zone.com_li7g.name
  proxied = false
  ttl     = 1
  type    = "TXT"
  content = "v=spf1 include:_spf.mx.cloudflare.net redirect=smtp.${cloudflare_zone.com_li7g.name}"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_dns_record" "li7g_smtp_spf" {
  name    = "smtp.${cloudflare_zone.com_li7g.name}"
  proxied = false
  ttl     = 1
  type    = "TXT"
  content = "v=spf1 a ~all"
  zone_id = cloudflare_zone.com_li7g.id
}

# github pages dns challange

resource "cloudflare_dns_record" "github_pages_challenge" {
  name    = "_github-pages-challenge-linyinfeng.${cloudflare_zone.com_li7g.name}"
  proxied = false
  ttl     = 1
  type    = "TXT"
  content = "6d2a79cedb6068b2a2b13ed18ccf4e"
  zone_id = cloudflare_zone.com_li7g.id
}

# b2

resource "cloudflare_dns_record" "li7g_b2" {
  name    = "b2.${cloudflare_zone.com_li7g.name}"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  content = module.b2_download_url.host
  zone_id = cloudflare_zone.com_li7g.id
}

# Ruleset

resource "cloudflare_ruleset" "li7g_http_config_settings" {
  name        = "acme-challenge"
  description = "Disable SSL for ACME challenge"
  kind        = "zone"
  zone_id     = cloudflare_zone.com_li7g.id
  phase       = "http_config_settings"

  rules = [{
    enabled = true
    action  = "set_config"
    action_parameters = {
      automatic_https_rewrites = false
      ssl                      = "off"
    }
    expression  = <<EOT
      (starts_with(http.request.uri.path, "/.well-known/acme-challenge/"))
    EOT
    description = "Disable SSL for ACME challenge"
  }]
}

resource "cloudflare_ruleset" "li7g_http_request_firewall_custom" {
  name        = "block-cn-traffic"
  description = "Block CN GET traffic for some hosts"
  kind        = "zone"
  zone_id     = cloudflare_zone.com_li7g.id
  phase       = "http_request_firewall_custom"

  rules = [{
    enabled     = true
    action      = "block"
    expression  = <<EOT
      (
        ip.geoip.country eq "CN" and
        http.request.method eq "GET" and
        ( http.host eq "pb.li7g.com" or
          http.host eq "social.li7g.com" or
          http.host eq "mastodon.li7g.com" or
          http.host eq "matrix.li7g.com" or
          http.host eq "ace-bot.li7g.com")
      )
    EOT
    description = "Block Traffic to some site from CN"
  }]
}

resource "cloudflare_ruleset" "li7g_http_request_cache_settings" {
  name        = "cache-settings"
  description = "Cache settings"
  kind        = "zone"
  zone_id     = cloudflare_zone.com_li7g.id
  phase       = "http_request_cache_settings"

  rules = [{
    enabled     = true
    action      = "set_cache_settings"
    expression  = <<EOT
      (
        http.host eq "pb.li7g.com" or
        http.host eq "cache.li7g.com" or
        http.host eq "oranc.li7g.com"
      )
    EOT
    description = "Set cache settings rule"
    action_parameters = {
      cache = true # cache everything
    }
  }]
}

# Email routing

resource "cloudflare_email_routing_settings" "li7g" {
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_email_routing_rule" "admin_li7g" {
  zone_id = cloudflare_zone.com_li7g.id
  name    = "admin"
  enabled = true
  matchers = [{
    type  = "literal"
    field = "to"
    value = "admin@li7g.com"
    }, {
    type  = "literal"
    field = "to"
    value = "postmaster@li7g.com"
  }]
  actions = [{
    type  = "forward"
    value = ["lin.yinfeng@outlook.com"]
  }]
}

resource "cloudflare_email_routing_catch_all" "li7g" {
  zone_id = cloudflare_zone.com_li7g.id
  name    = "catch all"
  enabled = true
  matchers = [{
    type = "all"
  }]
  actions = [{
    type  = "drop"
    value = []
  }]
}

# R2 Object storage

resource "cloudflare_r2_bucket" "cache" {
  account_id    = local.cloudflare_main_account_id
  name          = "cache-li7g-com"
  location      = "APAC" # Asia Pacific
  storage_class = "Standard"
}

resource "cloudflare_r2_custom_domain" "cache" {
  account_id  = local.cloudflare_main_account_id
  enabled     = true
  bucket_name = cloudflare_r2_bucket.cache.name
  domain      = "cache.${cloudflare_zone.com_li7g.name}"
  zone_id     = cloudflare_zone.com_li7g.id
}

resource "cloudflare_api_token" "cache" {
  name   = "cache"
  status = "active"
  policies = [{
    effect = "allow"
    permission_groups = [
      { id = local.permissions_groups_map["Workers R2 Storage Bucket Item Write"] }
    ]
    resources = {
      "com.cloudflare.edge.r2.bucket.${local.cloudflare_main_account_id}_default_${cloudflare_r2_bucket.cache.name}" : "*"
    }
  }]
}

output "r2_s3_api_url" {
  value     = "${local.cloudflare_main_account_id}.r2.cloudflarestorage.com"
  sensitive = true
}
output "r2_cache_bucket_name" {
  value     = cloudflare_r2_bucket.cache.name
  sensitive = false
}
output "r2_cache_key_id" {
  value     = cloudflare_api_token.cache.id
  sensitive = false
}

output "r2_cache_access_key" {
  value     = sha256(cloudflare_api_token.cache.value)
  sensitive = true
}

# TODO copy nix-cache-info
