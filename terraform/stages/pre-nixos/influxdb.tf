locals {
  # use grafana cloud
  influxdb_url = grafana_cloud_stack.yinfeng.influx_url
}
output "influxdb_url" {
  value     = local.influxdb_url
  sensitive = false
}
output "influxdb_username" {
  value = grafana_cloud_stack.yinfeng.prometheus_user_id
}
output "influxdb_token" {
  value     = grafana_cloud_access_policy_token.logging.token
  sensitive = true
}
