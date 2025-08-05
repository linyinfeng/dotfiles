provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

resource "tls_private_key" "acme" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "acme_registration" "main" {
  account_key_pem = tls_private_key.acme.private_key_pem
  email_address   = "lin.yinfeng@outlook.com"
}

resource "acme_certificate" "li7g_com" {
  account_key_pem = acme_registration.main.account_key_pem
  key_type        = "P384"
  common_name     = "li7g.com"
  subject_alternative_names = [
    "*.li7g.com",
    "*.ts.li7g.com",
    "*.zt.li7g.com",
    "*.dn42.li7g.com",
    "*.endpoints.li7g.com",
  ]

  dns_challenge {
    provider = "cloudflare"
    config = {
      CF_DNS_API_TOKEN = data.sops_file.terraform.data["cloudflare.api-token"]
    }
  }
}

output "acme_li7g_com_private_key_pem" {
  value     = acme_certificate.li7g_com.private_key_pem
  sensitive = true
}

output "acme_li7g_com_certificate_pem" {
  value = acme_certificate.li7g_com.certificate_pem
}

output "acme_li7g_com_issuer_pem" {
  value = acme_certificate.li7g_com.issuer_pem
}

output "acme_li7g_com_full_chain_pem" {
  value = "${acme_certificate.li7g_com.certificate_pem}${acme_certificate.li7g_com.issuer_pem}"
}
