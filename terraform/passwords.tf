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
resource "random_password" "rcon_retro" {
  length  = 32
  special = false
}
output "rcon_retro_password" {
  value     = random_password.rcon_retro.result
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
