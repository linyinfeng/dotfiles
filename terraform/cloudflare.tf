provider "cloudflare" {
  api_token = data.sops_file.terraform.data["cloudflare.api-token"]
}

# -------------
# DDNS and ACME token

data "cloudflare_api_token_permission_groups" "all" {}

resource "cloudflare_api_token" "ddns" {
  name = "ddns-acme"

  policy {
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.zone["Zone Read"],
      data.cloudflare_api_token_permission_groups.all.zone["Zone Settings Read"],
      data.cloudflare_api_token_permission_groups.all.zone["DNS Write"],
    ]
    resources = {
      "com.cloudflare.api.account.zone.*" = "*"
    }
  }
}

output "cloudflare_token" {
  value     = cloudflare_api_token.ddns.value
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
  account_id = local.cloudflare_main_account_id
  zone       = "li7g.com"
}

# ttl = 1 for automatic

# CNAME records

resource "cloudflare_record" "li7g_home" {
  name    = "home"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  value   = "ae370c7d335a.sn.mynetname.net"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g" {
  name    = "li7g.com"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = "vultr.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

locals {
  service_cname_mappings = {
    nuc-proxy       = { on = "vultr", proxy = true }
    portal          = { on = "vultr", proxy = true }
    tar             = { on = "vultr", proxy = true }
    pgp-public-key  = { on = "vultr", proxy = true }
    hydra           = { on = "nuc", proxy = false }
    transmission    = { on = "nuc", proxy = false }
    jellyfin        = { on = "nuc", proxy = false }
    vault           = { on = "rica", proxy = true }
    pb              = { on = "rica", proxy = true }
    git             = { on = "rica", proxy = true }
    box             = { on = "rica", proxy = true }
    minio           = { on = "rica", proxy = false }
    minio-console   = { on = "rica", proxy = true }
    mastodon        = { on = "rica", proxy = true }
    social          = { on = "rica", proxy = true }
    grafana         = { on = "rica", proxy = true }
    influxdb        = { on = "rica", proxy = true }
    loki            = { on = "rica", proxy = true }
    alertmanager    = { on = "rica", proxy = true }
    static          = { on = "rica", proxy = true }
    "shanghai.derp" = { on = "tencent", proxy = false }
    dst             = { on = "tencent", proxy = false }
    matrix-qq       = { on = "tencent", proxy = false }
    matrix          = { on = "hil0", proxy = true }
    smtp            = { on = "hil0", proxy = false }
  }
}

resource "cloudflare_record" "general_cname" {
  for_each = local.service_cname_mappings

  name    = each.key
  proxied = each.value.proxy
  ttl     = 1
  type    = "CNAME"
  value   = "${each.value.on}.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "general_zerotier_cname" {
  for_each = local.service_cname_mappings

  name    = "${each.key}.zt"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  value   = "${each.value.on}.zt.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "general_tailscale_cname" {
  for_each = local.service_cname_mappings

  name    = "${each.key}.ts"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  value   = "${each.value.on}.ts.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

# localhost record

resource "cloudflare_record" "localhost_a" {
  name    = "localhost"
  proxied = false
  ttl     = 1
  type    = "A"
  value   = "127.0.0.1"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "localhost_aaaa" {
  name    = "localhost"
  proxied = false
  ttl     = 1
  type    = "AAAA"
  value   = "::1"
  zone_id = cloudflare_zone.com_li7g.id
}

# ad-hoc ddns record

resource "cloudflare_record" "mc" {
  name    = "mc"
  proxied = false
  ttl     = 1
  type    = "A"
  value   = "127.0.0.1"
  zone_id = cloudflare_zone.com_li7g.id
  lifecycle { ignore_changes = [value] }
}

# smtp records for sending

resource "cloudflare_record" "li7g_dkim" {
  name    = "default._domainkey"
  proxied = false
  ttl     = 1
  type    = "TXT"
  value   = "v=DKIM1; k=${local.dkim_algorithm}; p=${local.dkim_public_key}"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_dmarc" {
  name    = "_dmarc"
  proxied = false
  ttl     = 1
  type    = "TXT"
  value   = "v=DMARC1; p=quarantine; ruf=mailto:postmaster@li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_spf" {
  name    = "li7g.com"
  proxied = false
  ttl     = 1
  type    = "TXT"
  value   = "v=spf1 include:_spf.mx.cloudflare.net redirect=smtp.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_smtp_spf" {
  name    = "smtp"
  proxied = false
  ttl     = 1
  type    = "TXT"
  value   = "v=spf1 a ~all"
  zone_id = cloudflare_zone.com_li7g.id
}

# github pages dns challange

resource "cloudflare_record" "github_pages_challenge" {
  name    = "_github-pages-challenge-linyinfeng"
  proxied = false
  ttl     = 1
  type    = "TXT"
  value   = "6d2a79cedb6068b2a2b13ed18ccf4e"
  zone_id = cloudflare_zone.com_li7g.id
}

# acme

resource "cloudflare_page_rule" "acme" {
  zone_id  = cloudflare_zone.com_li7g.id
  target   = "*.li7g.com/.well-known/acme-challenge/*"
  priority = 1
  actions {
    automatic_https_rewrites = "off"
    ssl                      = "off"
  }
}

# cache

resource "cloudflare_record" "li7g_cache" {
  name    = "cache"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = module.b2_download_url.host
  zone_id = cloudflare_zone.com_li7g.id
}
resource "cloudflare_record" "li7g_cache_overlay" {
  name    = "cache-overlay"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = "vultr.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}
resource "cloudflare_ruleset" "li7g_rewrite" {
  kind        = "zone"
  zone_id     = cloudflare_zone.com_li7g.id
  name        = "rewrite"
  description = "URL Rewrite"
  phase       = "http_request_transform"
  rules {
    enabled     = true
    description = "Rewrite cache path"
    expression  = "(http.host eq \"cache.li7g.com\")"
    action      = "rewrite"
    action_parameters {
      uri {
        path {
          expression = "concat(\"/file/${b2_bucket.cache.bucket_name}\", http.request.uri.path)"
        }
      }
    }
  }
}

# CN Block

resource "cloudflare_filter" "li7g_cn_traffic" {
  zone_id     = cloudflare_zone.com_li7g.id
  description = "Traffic to some site from CN"
  expression  = <<EOT
    (
      ip.geoip.country eq "CN" and
      ( http.host eq "pb.li7g.com" or
        http.host eq "social.li7g.com" or
        http.host eq "mastodon.li7g.com" )
    )
  EOT
}
resource "cloudflare_firewall_rule" "li7g_block_cn_traffic" {
  zone_id     = cloudflare_zone.com_li7g.id
  description = "Block Traffic to some site from CN"
  filter_id   = cloudflare_filter.li7g_cn_traffic.id
  action      = "block"
}

# http request cache settings

resource "cloudflare_ruleset" "li7g_http_request_cache_settings" {
  zone_id     = cloudflare_zone.com_li7g.id
  name        = "cache-settings"
  description = "Cache settings"
  kind        = "zone"
  phase       = "http_request_cache_settings"

  rules {
    enabled     = true
    action      = "set_cache_settings"
    expression  = <<EOT
      (
        http.host eq "pb.li7g.com" or
        http.host eq "cache.li7g.com"
      )
    EOT
    description = "Set cache settings rule"
    action_parameters {
      cache = true # cache everything
    }
  }
}

# Email routing

resource "cloudflare_email_routing_settings" "li7g" {
  zone_id = cloudflare_zone.com_li7g.id
  enabled = true
}

resource "cloudflare_email_routing_rule" "postmaster_li7g" {
  zone_id = cloudflare_zone.com_li7g.id
  name    = "postmaster"
  enabled = true
  matcher {
    type  = "literal"
    field = "to"
    value = "postmaster@li7g.com"
  }
  action {
    type  = "forward"
    value = ["lin.yinfeng@outlook.com"]
  }
}

resource "cloudflare_email_routing_rule" "admin_li7g" {
  zone_id = cloudflare_zone.com_li7g.id
  name    = "admin"
  enabled = true
  matcher {
    type  = "literal"
    field = "to"
    value = "admin@li7g.com"
  }
  action {
    type  = "forward"
    value = ["lin.yinfeng@outlook.com"]
  }
}

resource "cloudflare_email_routing_catch_all" "li7g" {
  zone_id = cloudflare_zone.com_li7g.id
  name    = "catch all"
  enabled = true
  matcher {
    type = "all"
  }
  action {
    type  = "drop"
    value = []
  }
}
