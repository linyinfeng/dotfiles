provider "grafana" {
  alias         = "cloud"
  cloud_api_key = data.sops_file.terraform.data["grafana.token"]
}
resource "grafana_cloud_stack" "yinfeng" {
  provider    = grafana.cloud
  name        = "yinfeng.grafana.net"
  slug        = "yinfeng"
  region_slug = "prod-us-east-0"
}
resource "grafana_cloud_access_policy" "promtail" {
  provider = grafana.cloud

  region       = grafana_cloud_stack.yinfeng.region_slug
  name         = "promtail"
  display_name = "Promtail"

  scopes = ["metrics:write", "logs:write", "traces:write"]
  realm {
    type       = "org"
    identifier = grafana_cloud_stack.yinfeng.org_id
  }
}
resource "grafana_cloud_access_policy_token" "promtail" {
  provider = grafana.cloud

  region           = grafana_cloud_stack.yinfeng.region_slug
  access_policy_id = grafana_cloud_access_policy.promtail.policy_id
  name             = "promtail"
  display_name     = "Promtail Token"
}
output "loki_username" {
  value     = tostring(grafana_cloud_stack.yinfeng.logs_user_id)
  sensitive = false
}
output "loki_host" {
  value     = regex("^(\\w+)://(.*)$", grafana_cloud_stack.yinfeng.logs_url)[1]
  sensitive = false
}
output "loki_password" {
  value     = grafana_cloud_access_policy_token.promtail.token
  sensitive = true
}

provider "grafana" {
  url  = "https://yinfeng.grafana.net"
  auth = data.sops_file.terraform.data["grafana.stack-token"]
}
resource "grafana_data_source" "influxdb" {
  uid  = "influxdb"
  name = "InfluxDB"
  type = "influxdb"
  url  = local.influxdb_url
  json_data_encoded = jsonencode({
    version      = "Flux"
    organization = "main-org"
  })
  secure_json_data_encoded = jsonencode({
    token = random_password.influxdb_token.result
  })
}
resource "grafana_folder" "infrastructure" {
  title = "Infrastructure"
}
resource "grafana_dashboard" "http_response" {
  config_json = file("${path.module}/grafana/dashboards/http-response.json")
  folder      = grafana_folder.infrastructure.uid
}
resource "grafana_dashboard" "minecraft" {
  config_json = file("${path.module}/grafana/dashboards/minecraft.json")
  folder      = grafana_folder.infrastructure.uid
}
resource "grafana_dashboard" "minio" {
  config_json = file("${path.module}/grafana/dashboards/minio.json")
  folder      = grafana_folder.infrastructure.uid
}
resource "grafana_dashboard" "system" {
  config_json = file("${path.module}/grafana/dashboards/system.json")
  folder      = grafana_folder.infrastructure.uid
}
