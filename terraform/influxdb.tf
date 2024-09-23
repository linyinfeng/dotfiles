locals {
  # currently use self-hosted influxdb
  # influxdb cloud is too expensive
  influxdb_url = "https://influxdb.li7g.com"
}
output "influxdb_url" {
  value     = local.influxdb_url
  sensitive = false
}
