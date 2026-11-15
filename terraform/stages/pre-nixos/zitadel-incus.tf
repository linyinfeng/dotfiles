# Cluster administration: only explicitly assigned administrators may log in.
# Applications in this project share this policy and its role assignments.
moved {
  from = zitadel_project.incus
  to   = zitadel_project.infrastructure
}

resource "zitadel_project" "infrastructure" {
  org_id                 = one(data.zitadel_organizations.li7g.ids)
  name                   = "Infrastructure"
  project_role_assertion = true
  project_role_check     = true
  has_project_check      = true
}

resource "zitadel_project_role" "incus_admin" {
  org_id       = zitadel_project.infrastructure.org_id
  project_id   = zitadel_project.infrastructure.id
  role_key     = "admin"
  display_name = "Incus administrator"
}

data "zitadel_human_users" "incus_admin" {
  org_id       = one(data.zitadel_organizations.li7g.ids)
  email        = "lin.yinfeng@outlook.com"
  email_method = "TEXT_QUERY_METHOD_EQUALS_IGNORE_CASE"

  lifecycle {
    postcondition {
      condition     = length(self.user_ids) == 1
      error_message = "The Incus administrator email must match exactly one Zitadel user."
    }
  }
}

resource "zitadel_user_grant" "incus_admin" {
  org_id     = zitadel_project.infrastructure.org_id
  project_id = zitadel_project.infrastructure.id
  user_id    = one(data.zitadel_human_users.incus_admin.user_ids)
  role_keys  = [zitadel_project_role.incus_admin.role_key]
}

resource "zitadel_application_oidc" "incus" {
  org_id     = zitadel_project.infrastructure.org_id
  project_id = zitadel_project.infrastructure.id
  name       = "Incus CLI"

  app_type         = "OIDC_APP_TYPE_NATIVE"
  auth_method_type = "OIDC_AUTH_METHOD_TYPE_NONE"
  version          = "OIDC_VERSION_1_0"
  dev_mode         = false

  redirect_uris  = []
  response_types = ["OIDC_RESPONSE_TYPE_CODE"]
  grant_types = [
    "OIDC_GRANT_TYPE_DEVICE_CODE",
    "OIDC_GRANT_TYPE_REFRESH_TOKEN",
  ]

  # The server must also authorize OIDC identities explicitly; audience alone
  # does not restrict which users may administer Incus.
  access_token_type           = "OIDC_TOKEN_TYPE_JWT"
  access_token_role_assertion = true
}

output "zitadel_incus_client_id" {
  value = nonsensitive(zitadel_application_oidc.incus.client_id)
}

output "zitadel_incus_project_id" {
  value = zitadel_project.infrastructure.id
}

output "zitadel_incus_server_config" {
  value = {
    "oidc.issuer"               = local.zitadel_issuer
    "oidc.client.id"            = nonsensitive(zitadel_application_oidc.incus.client_id)
    "oidc.audience"             = zitadel_project.infrastructure.id
    "oidc.scopes"               = "openid,profile,email,offline_access,urn:zitadel:iam:org:project:id:${zitadel_project.infrastructure.id}:aud"
    "oidc.claim"                = "sub"
    "authorization.client.oidc" = "scriptlet"
    "authorization.scriptlet"   = <<-SCRIPT
      def authorize(details, object, entitlement):
          return details.Protocol == "oidc" and details.Username == ${jsonencode(one(data.zitadel_human_users.incus_admin.user_ids))}
    SCRIPT
  }
}
