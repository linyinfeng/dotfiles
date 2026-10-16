locals {
  zitadel_domain = nonsensitive(data.sops_file.terraform.data["zitadel.domain"])
  zitadel_issuer = "https://${local.zitadel_domain}"
}

provider "zitadel" {
  domain       = local.zitadel_domain
  access_token = data.sops_file.terraform.data["zitadel.token"]
}

data "zitadel_organizations" "li7g" {
  is_default = true
}

resource "zitadel_project" "li7g" {
  name   = "li7g.com"
  org_id = one(data.zitadel_organizations.li7g.ids)
}

resource "zitadel_application_oidc" "synapse" {
  org_id     = zitadel_project.li7g.org_id
  project_id = zitadel_project.li7g.id
  name       = "Matrix Synapse"

  redirect_uris             = ["https://matrix.li7g.com/_synapse/client/oidc/callback"]
  post_logout_redirect_uris = ["https://matrix.li7g.com/"]

  response_types = ["OIDC_RESPONSE_TYPE_CODE"]
  grant_types = [
    "OIDC_GRANT_TYPE_AUTHORIZATION_CODE",
    "OIDC_GRANT_TYPE_REFRESH_TOKEN",
  ]

  # confidential client, matching Synapse's default client_secret_basic
  app_type         = "OIDC_APP_TYPE_WEB"
  auth_method_type = "OIDC_AUTH_METHOD_TYPE_BASIC"
  version          = "OIDC_VERSION_1_0"

  # dev_mode skips the OIDC compliance checks
  dev_mode = false

  # Synapse reads the userinfo endpoint, this makes the id_token carry the same claims
  id_token_userinfo_assertion = true

  access_token_type = "OIDC_TOKEN_TYPE_BEARER"
}

output "zitadel_issuer" {
  value     = local.zitadel_issuer
  sensitive = false
}
output "zitadel_synapse_client_id" {
  # the provider marks client_id sensitive, though it is not a secret
  value     = nonsensitive(zitadel_application_oidc.synapse.client_id)
  sensitive = false
}
output "zitadel_synapse_client_secret" {
  value     = zitadel_application_oidc.synapse.client_secret
  sensitive = true
}
