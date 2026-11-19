resource "zitadel_application_oidc" "personal_oidc" {
  org_id     = zitadel_project.services.org_id
  project_id = zitadel_project.services.id
  name       = "Personal Apps"

  redirect_uris = [
    "https://hermes.li7g.com:8443/oauth2/callback",
    "https://hermes-proxy.li7g.com/oauth2/callback",
  ]
  response_types              = ["OIDC_RESPONSE_TYPE_CODE"]
  grant_types                 = ["OIDC_GRANT_TYPE_AUTHORIZATION_CODE"]
  app_type                    = "OIDC_APP_TYPE_WEB"
  auth_method_type            = "OIDC_AUTH_METHOD_TYPE_BASIC"
  version                     = "OIDC_VERSION_1_0"
  dev_mode                    = false
  id_token_userinfo_assertion = true
  access_token_type           = "OIDC_TOKEN_TYPE_BEARER"
}

resource "random_id" "personal_oidc_cookie" {
  byte_length = 32
}

output "zitadel_personal_oidc_client_id" {
  value = nonsensitive(zitadel_application_oidc.personal_oidc.client_id)
}

output "zitadel_personal_oidc_client_secret" {
  value     = zitadel_application_oidc.personal_oidc.client_secret
  sensitive = true
}

output "personal_oidc_cookie_secret" {
  value     = random_id.personal_oidc_cookie.b64_url
  sensitive = true
}
