provider "htpasswd" {
}

resource "random_pet" "transmission_username" {
}
output "transmission_username" {
  value     = random_pet.transmission_username.id
  sensitive = true
}
resource "random_password" "transmission" {
  length = 32
}
resource "random_password" "transmission_salt" {
  length = 8
}
resource "htpasswd_password" "transmission" {
  password = random_password.transmission.result
  salt     = random_password.transmission_salt.result
}
output "transmission_password" {
  value     = random_password.transmission.result
  sensitive = true
}
output "transmission_hashed_password" {
  value     = htpasswd_password.transmission.sha512
  sensitive = true
}
resource "random_password" "loki" {
  length  = 32
  special = false
}
resource "random_password" "loki_salt" {
  length = 8
}
resource "htpasswd_password" "loki" {
  password = random_password.loki.result
  salt     = random_password.loki_salt.result
}
output "loki_password" {
  value     = random_password.loki.result
  sensitive = true
}
output "loki_hashed_password" {
  value     = htpasswd_password.loki.sha512
  sensitive = true
}
resource "random_password" "influxdb" {
  length  = 32
  special = false
}
output "influxdb_password" {
  value     = random_password.influxdb.result
  sensitive = true
}
resource "random_password" "influxdb_token" {
  length  = 64
  special = false
}
output "influxdb_token" {
  value     = random_password.influxdb_token.result
  sensitive = true
}
resource "random_password" "rcon" {
  length  = 32
  special = false
}
output "rcon_password" {
  value     = random_password.rcon.result
  sensitive = true
}
resource "random_password" "grafana" {
  length  = 32
  special = false
}
output "grafana_password" {
  value     = random_password.grafana.result
  sensitive = true
}
resource "random_password" "vaultwarden_admin_token" {
  length  = 64
  special = false
}
output "vaultwarden_admin_token" {
  value     = random_password.vaultwarden_admin_token.result
  sensitive = true
}
resource "random_password" "mail" {
  length  = 32
  special = false
}
output "mail_password" {
  value     = random_password.mail.result
  sensitive = true
}
resource "random_uuid" "portal_client_id" {
}
output "portal_client_id" {
  value     = random_uuid.portal_client_id.result
  sensitive = true
}
resource "random_password" "alertmanager" {
  length  = 32
  special = false
}
resource "random_password" "alertmanager_salt" {
  length = 8
}
resource "htpasswd_password" "alertmanager" {
  password = random_password.alertmanager.result
  salt     = random_password.alertmanager_salt.result
}
output "alertmanager_password" {
  value     = random_password.alertmanager.result
  sensitive = true
}
output "alertmanager_hashed_password" {
  value     = htpasswd_password.alertmanager.bcrypt
  sensitive = true
}
resource "random_password" "seahub" {
  length  = 32
  special = false
}
output "seahub_password" {
  value     = random_password.seahub.result
  sensitive = true
}
resource "tls_private_key" "hydra_builder" {
  algorithm = "ED25519"
}
data "tls_public_key" "hydra_builder" {
  private_key_pem = tls_private_key.hydra_builder.private_key_pem
}
output "hydra_builder_private_key" {
  value     = tls_private_key.hydra_builder.private_key_openssh
  sensitive = true
}
output "hydra_builder_public_key" {
  value     = data.tls_public_key.hydra_builder.public_key_openssh
  sensitive = false
}
resource "random_password" "code_server" {
  length  = 32
  special = false
}
output "code_server_hashed_password" {
  value     = sha256(random_password.code_server.result)
  sensitive = true
}
resource "random_password" "mautrix_telegram_appservice_as_token" {
  length  = 32
  special = false
}
output "mautrix_telegram_appservice_as_token" {
  value     = random_password.mautrix_telegram_appservice_as_token.result
  sensitive = true
}
resource "random_password" "mautrix_telegram_appservice_hs_token" {
  length  = 32
  special = false
}
output "mautrix_telegram_appservice_hs_token" {
  value     = random_password.mautrix_telegram_appservice_hs_token.result
  sensitive = true
}
resource "random_password" "matrix_qq_appservice_as_token" {
  length  = 32
  special = false
}
output "matrix_qq_appservice_as_token" {
  value     = random_password.matrix_qq_appservice_as_token.result
  sensitive = true
}
resource "random_password" "matrix_qq_appservice_hs_token" {
  length  = 32
  special = false
}
output "matrix_qq_appservice_hs_token" {
  value     = random_password.matrix_qq_appservice_hs_token.result
  sensitive = true
}
