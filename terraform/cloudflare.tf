provider "cloudflare" {
  email   = data.sops_file.terraform.data["cloudflare.email"]
  api_key = data.sops_file.terraform.data["cloudflare.api-key"]
}

# -------------
# DDNS and ACME token

data "cloudflare_api_token_permission_groups" "all" {}

resource "cloudflare_api_token" "ddns" {
  name = "ddns-acme"

  policy {
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.permissions["Zone Read"],
      data.cloudflare_api_token_permission_groups.all.permissions["Zone Settings Read"],
      data.cloudflare_api_token_permission_groups.all.permissions["DNS Write"],
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
# Zones

resource "cloudflare_zone" "com_li7g" {
  zone = "li7g.com"
  lifecycle {
    ignore_changes = [
      account_id
    ]
  }
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

resource "cloudflare_record" "li7g_dst" {
  name    = "dst"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  value   = "tencent.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_mc" {
  name    = "mc"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  value   = "nuc.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_byrmc_retro" {
  name    = "byrmc-retro"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  value   = "tencent.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_matrix" {
  name    = "matrix"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = "rica.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_nuc_proxy" {
  name    = "nuc-proxy"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = "vultr.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_portal" {
  name    = "portal"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = "vultr.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_derp_shanghai" {
  name    = "shanghai.derp"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  value   = "tencent.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_tar" {
  name    = "tar"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = "vultr.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_vault" {
  name    = "vault"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = "rica.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_influxdb" {
  name    = "influxdb"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = "rica.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_influxdb_zt" {
  name    = "influxdb.zt"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  value   = "rica.zt.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_loki" {
  name    = "loki"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = "rica.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_loki_zt" {
  name    = "loki.zt"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  value   = "rica.zt.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_grafana" {
  name    = "grafana"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = "rica.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_hydra" {
  name    = "hydra"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  value   = "nuc.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_minio" {
  name    = "minio"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  value   = "rica.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_minio_overlay" {
  name    = "minio-overlay"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  value   = "minio.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_pb" {
  name    = "pb"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = "rica.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_minio_console" {
  name    = "minio-console"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = "minio.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_git" {
  name    = "git"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = "rica.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_transmission" {
  name    = "transmission"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  value   = "nuc.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_zt_transmission" {
  name    = "transmission.zt"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  value   = "nuc.zt.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

# smtp records for receiving

resource "cloudflare_record" "li7g_mx68" {
  name     = "li7g.com"
  priority = 68
  proxied  = false
  ttl      = 1
  type     = "MX"
  value    = "amir.mx.cloudflare.net"
  zone_id  = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_mx43" {
  name     = "li7g.com"
  priority = 43
  proxied  = false
  ttl      = 1
  type     = "MX"
  value    = "linda.mx.cloudflare.net"
  zone_id  = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_mx2" {
  name     = "li7g.com"
  priority = 2
  proxied  = false
  ttl      = 1
  type     = "MX"
  value    = "isaac.mx.cloudflare.net"
  zone_id  = cloudflare_zone.com_li7g.id
}

# smtp records for sending

resource "cloudflare_record" "li7g_smtp" {
  name    = "smtp"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  value   = "rica.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_smtp_zt" {
  name    = "smtp.zt"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  value   = "rica.zt.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}

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

# tailscale records

resource "cloudflare_record" "li7g_ts_g150t" {
  name    = "g150ts.ts"
  proxied = false
  ttl     = 1
  type    = "A"
  value   = "100.107.253.26"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_ts_mix2s" {
  name    = "mix2s.ts"
  proxied = false
  ttl     = 1
  type    = "A"
  value   = "100.97.39.42"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_ts_rica" {
  name    = "rica.ts"
  proxied = false
  ttl     = 1
  type    = "A"
  value   = "100.75.88.79"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_ts_nuc" {
  name    = "nuc.ts"
  proxied = false
  ttl     = 1
  type    = "A"
  value   = "100.95.57.26"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_ts_t460p" {
  name    = "t460p.ts"
  proxied = false
  ttl     = 1
  type    = "A"
  value   = "100.106.218.38"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_ts_tencent" {
  name    = "tencent.ts"
  proxied = false
  ttl     = 1
  type    = "A"
  value   = "100.98.18.47"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_ts_vultr" {
  name    = "vultr.ts"
  proxied = false
  ttl     = 1
  type    = "A"
  value   = "100.98.21.41"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_ts_x200s" {
  name    = "x200s.ts"
  proxied = false
  ttl     = 1
  type    = "A"
  value   = "100.115.15.96"
  zone_id = cloudflare_zone.com_li7g.id
}

resource "cloudflare_record" "li7g_ts_xps8930" {
  name    = "xps8930.ts"
  proxied = false
  ttl     = 1
  type    = "A"
  value   = "100.67.95.76"
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

resource "cloudflare_record" "li7g_cache_old" {
  name    = "cache-old"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = "minio.li7g.com"
  zone_id = cloudflare_zone.com_li7g.id
}
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
resource "cloudflare_page_rule" "cache" {
  zone_id  = cloudflare_zone.com_li7g.id
  target   = "cache.li7g.com/*"
  priority = 2
  actions {
    cache_level = "cache_everything"
  }
}

# pastebin

resource "cloudflare_filter" "li7g_pb_cn_traffic" {
  zone_id     = cloudflare_zone.com_li7g.id
  description = "Traffic to pb.li7b.com from CN"
  expression  = "(http.host eq \"pb.li7g.com\" and ip.geoip.country eq \"CN\")"
}
resource "cloudflare_firewall_rule" "li7g_block_pb_cn_traffic" {
  zone_id     = cloudflare_zone.com_li7g.id
  description = "Block Traffic to pb.li7b.com from CN"
  filter_id   = cloudflare_filter.li7g_pb_cn_traffic.id
  action      = "block"
}
