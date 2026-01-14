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
  length  = 8
  special = false
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
  length  = 8
  special = false
}
resource "htpasswd_password" "loki" {
  password = random_password.loki.result
  salt     = random_password.loki_salt.result
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
  length  = 8
  special = false
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
resource "random_password" "hydra_webhook_github" {
  length  = 32
  special = false
}
output "hydra_webhook_github_secret" {
  value     = random_password.hydra_webhook_github.result
  sensitive = true
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
resource "random_password" "fw_proxy_external_controller_secret" {
  length  = 32
  special = false
}
output "fw_proxy_external_controller_secret" {
  value     = random_password.fw_proxy_external_controller_secret.result
  sensitive = true
}

resource "random_pet" "hledger_username" {
}
output "hledger_username" {
  value     = random_pet.hledger_username.id
  sensitive = true
}
resource "random_password" "hledger" {
  length = 32
}
resource "random_password" "hledger_salt" {
  length  = 8
  special = false
}
resource "htpasswd_password" "hledger" {
  password = random_password.hledger.result
  salt     = random_password.hledger_salt.result
}
output "hledger_password" {
  value     = random_password.hledger.result
  sensitive = true
}
output "hledger_hashed_password" {
  value     = htpasswd_password.hledger.sha512
  sensitive = true
}
resource "random_password" "keycloak_db" {
  length  = 32
  special = false
}
output "keycloak_db_password" {
  value     = random_password.keycloak_db.result
  sensitive = true
}
resource "shell_sensitive_script" "syncv3_secret" {
  lifecycle_commands {
    create = <<EOT
      set -e
      secret=$(openssl rand -hex 32)
      jq --null-input \
        --arg secret "$secret" \
        '{"secret": $secret}'
    EOT
    delete = <<EOT
      # do nothing
    EOT
  }
}
output "syncv3_secret" {
  value     = shell_sensitive_script.syncv3_secret.output.secret
  sensitive = true
}
resource "random_password" "rathole_ad_hoc_token" {
  length  = 32
  special = false
}
resource "random_password" "rathole_salt" {
  length  = 8
  special = false
}
resource "htpasswd_password" "rathole" {
  password = random_password.rathole_ad_hoc_token.result
  salt     = random_password.rathole_salt.result
}
output "rathole_ad_hoc_token" {
  value     = random_password.rathole_ad_hoc_token.result
  sensitive = true
}
output "rathole_hashed_password" {
  value     = htpasswd_password.rathole.sha512
  sensitive = true
}
resource "random_password" "nextcloud_admin_password" {
  length  = 32
  special = false
}
output "nextcloud_admin_password" {
  value     = random_password.nextcloud_admin_password.result
  sensitive = true
}
resource "random_password" "ntfy_sh_topic_secret" {
  length  = 32
  upper   = false
  special = false
}
output "ntfy_sh_topic_secret" {
  value     = random_password.ntfy_sh_topic_secret.result
  sensitive = true
}
resource "tls_private_key" "iperf" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
output "iperf_private_key" {
  value     = tls_private_key.iperf.private_key_pem
  sensitive = true
}
data "tls_public_key" "iperf" {
  private_key_pem = tls_private_key.iperf.private_key_pem
}
output "iperf_public_key" {
  value     = data.tls_public_key.iperf.public_key_pem
  sensitive = false
}
resource "random_pet" "iperf_username" {
}
output "iperf_username" {
  value     = random_pet.iperf_username.id
  sensitive = true
}
resource "random_password" "iperf" {
  length  = 32
  special = false
}
output "iperf_password" {
  value     = random_password.iperf.result
  sensitive = true
}
output "iperf_hashed_password" {
  value     = "${random_pet.iperf_username.id},${sha256("{${random_pet.iperf_username.id}}${random_password.iperf.result}")}"
  sensitive = true
}
resource "random_password" "atuin_yinfeng" {
  length  = 64
  special = false
}
output "atuin_password_yinfeng" {
  value     = random_password.atuin_yinfeng.result
  sensitive = true
}
resource "random_password" "gnome_remote_desktop" {
  length  = 16
  special = false
}
output "gnome_remote_desktop_password" {
  value     = random_password.gnome_remote_desktop.result
  sensitive = true
}

resource "random_password" "mongodb_admin" {
  length  = 64
  special = false
}
output "mongodb_admin_password" {
  value     = random_password.mongodb_admin.result
  sensitive = true
}

resource "random_password" "mongodb_monitor" {
  length  = 64
  special = false
}
output "mongodb_monitor_password" {
  value     = random_password.mongodb_monitor.result
  sensitive = true
}


# SICP staging

resource "random_password" "mongodb_sicp_staging" {
  length  = 64
  special = false
}
output "mongodb_sicp_staging_password" {
  value     = random_password.mongodb_sicp_staging.result
  sensitive = true
}

resource "random_password" "rabbitmq_sicp_staging" {
  length  = 32
  special = false
}
output "rabbitmq_sicp_staging_password" {
  value     = random_password.rabbitmq_sicp_staging.result
  sensitive = true
}

resource "random_password" "sicp_staging_jwt_secret" {
  length  = 64
  special = false
}
output "sicp_staging_jwt_secret" {
  value     = random_password.sicp_staging_jwt_secret.result
  sensitive = true
}

resource "random_password" "sicp_staging_admin" {
  length  = 32
  special = false
}
output "sicp_staging_admin_password" {
  value     = random_password.sicp_staging_admin.result
  sensitive = true
}
resource "random_password" "sicp_staging_redis" {
  length  = 32
  special = false
}
output "sicp_staging_redis_password" {
  value     = random_password.sicp_staging_redis.result
  sensitive = true
}
resource "random_password" "sicp_tutorials" {
  length  = 16
  special = false
}
resource "random_password" "sicp_tutorials_salt" {
  length  = 8
  special = false
}
resource "htpasswd_password" "sicp_tutorials" {
  password = random_password.sicp_tutorials.result
  salt     = random_password.sicp_tutorials_salt.result
}
output "sicp_tutorials_password" {
  value     = random_password.sicp_tutorials.result
  sensitive = true
}
output "sicp_tutorials_hashed_password" {
  value     = htpasswd_password.sicp_tutorials.sha512
  sensitive = true
}
resource "random_password" "fw_proxy_subscription" {
  length  = 64
  special = false
}
output "fw_proxy_subscription_password" {
  value     = random_password.fw_proxy_subscription.result
  sensitive = true
}
resource "random_password" "pocket_id_encryption_key" {
  length  = 64
  special = true
}
output "pocket_id_encryption_key" {
  value     = random_password.pocket_id_encryption_key.result
  sensitive = true
}
