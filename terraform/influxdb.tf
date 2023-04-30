provider "influx" {
  url   = local.influxdb_url_cloud
  token = data.sops_file.terraform.data["influxdb.token"]
}
locals {
  influxdb_url_cloud = "https://us-east-1-1.aws.cloud2.influxdata.com"
  # influxdb_url = influxdb_url_cloud
  # currently use self-hosted influxdb
  # influxdb_url is too expensive
  influxdb_url = "https://influxdb.li7g.com"
}
output "influxdb_url" {
  value     = local.influxdb_url
  sensitive = false
}

resource "influx_bucket" "system" {
  name           = "system"
  retention_days = 30
}
resource "influx_bucket" "http" {
  name           = "http"
  retention_days = 30
}
resource "influx_bucket" "minio" {
  name           = "minio"
  retention_days = 30
}
resource "influx_bucket" "minecraft" {
  name           = "minecraft"
  retention_days = 30
}

resource "influx_authorization" "write" {
  name = "write"
  permission {
    action = "write"
    type   = "buckets"
  }
}
# currently use self-hosted influxdb
# output "influxdb_token" {
#   value     = influx_authorization.write.token
#   sensitive = true
# }
resource "influx_authorization" "grafana" {
  name = "grafana"
  permission {
    action = "read"
    type   = "buckets"
  }
}
