provider "grafana" {
  alias                     = "cloud"
  cloud_access_policy_token = data.sops_file.terraform.data["grafana.token"]
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
resource "grafana_folder" "application" {
  title = "Application"
}
resource "grafana_dashboard" "http_response" {
  config_json = file("${path.module}/grafana/dashboards/http-response.json")
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
resource "grafana_dashboard" "minecraft" {
  config_json = file("${path.module}/grafana/dashboards/minecraft.json")
  folder      = grafana_folder.application.uid
}


resource "grafana_rule_group" "infrastructure" {
  name             = "Infrastructure Rules"
  folder_uid       = grafana_folder.infrastructure.uid
  interval_seconds = 60
  rule {
    name           = "Systemd units failure"
    for            = "1m"
    condition      = "Threshold"
    no_data_state  = "OK"
    exec_err_state = "Error"
    annotations = {
    }
    labels = {
    }
    is_paused = false
    data {
      ref_id     = "Query"
      query_type = ""
      relative_time_range {
        from = 60
        to   = 0
      }
      datasource_uid = grafana_data_source.influxdb.uid
      model = jsonencode({
        datasource = {
          type = "influxdb"
          uid  = grafana_data_source.influxdb.uid
        }
        hide  = false
        query = <<-EOT
from(bucket: "system")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "systemd_units" and
                       r._field == "active_code" and
                       r._value == 3)
EOT
        refId = "Query"
      })
    }
    data {
      ref_id         = "Count"
      query_type     = ""
      datasource_uid = "__expr__"
      relative_time_range {
        from = 60
        to   = 0
      }
      model = jsonencode({
        datasource = {
          name = "Expression"
          type = "__expr__"
          uid  = "__expr__"
        }
        expression = "Query"
        hide       = false
        reducer    = "count"
        refId      = "Count"
        type       = "reduce"
      })
    }
    data {
      ref_id         = "Threshold"
      query_type     = ""
      datasource_uid = "__expr__"
      relative_time_range {
        from = 60
        to   = 0
      }
      model = jsonencode({
        conditions = [
          {
            evaluator = {
              params = [
                0,
              ]
              type = "gt"
            }
          },
        ]
        datasource = {
          name = "Expression"
          type = "__expr__"
          uid  = "__expr__"
        }
        expression = "Count"
        hide       = false
        refId      = "Threshold"
        type       = "threshold"
      })
    }
  }

  rule {
    name           = "HTTP Service Down"
    for            = "5m"
    condition      = "Threshold"
    no_data_state  = "OK"
    exec_err_state = "Error"
    annotations = {
    }
    labels = {
    }
    is_paused = false
    data {
      ref_id     = "Query"
      query_type = ""
      relative_time_range {
        from = 60
        to   = 0
      }
      datasource_uid = grafana_data_source.influxdb.uid
      model = jsonencode({
        datasource = {
          type = "influxdb"
          uid  = grafana_data_source.influxdb.uid
        }
        hide  = false
        query = <<-EOT
from(bucket: "http")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r["_measurement"] == "http_response" and
                       r["_field"] == "result_code" and
                       r._value != 0)
EOT
        refId = "Query"
      })
    }
    data {
      ref_id         = "Count"
      query_type     = ""
      datasource_uid = "__expr__"
      relative_time_range {
        from = 60
        to   = 0
      }
      model = jsonencode({
        datasource = {
          name = "Expression"
          type = "__expr__"
          uid  = "__expr__"
        }
        expression = "Query"
        hide       = false
        reducer    = "count"
        refId      = "Count"
        type       = "reduce"
      })
    }
    data {
      ref_id         = "Threshold"
      query_type     = ""
      datasource_uid = "__expr__"
      relative_time_range {
        from = 60
        to   = 0
      }
      model = jsonencode({
        conditions = [
          {
            evaluator = {
              params = [
                0,
              ]
              type = "gt"
            }
          },
        ]
        datasource = {
          name = "Expression"
          type = "__expr__"
          uid  = "__expr__"
        }
        expression = "Count"
        hide       = false
        refId      = "Threshold"
        type       = "threshold"
      })
    }
  }
}

resource "grafana_contact_point" "email" {
  name = "Email"

  email {
    addresses    = ["lin.yinfeng@outlook.com"]
    subject      = "{{ template \"default.title\" . }}"
    message      = "{{ template \"default.message\" . }}"
    single_email = true
  }
}

resource "grafana_contact_point" "telegram_push" {
  name = "Telegram Push"

  telegram {
    token   = data.sops_file.predefined.data["telegram_bot_push"]
    chat_id = 148111617
    message = "{{ template \"default.message\" . }}"
  }
}

# singleton resource
resource "grafana_notification_policy" "policy" {
  group_by = ["grafana_folder", "alertname"]
  # default contact point
  contact_point = grafana_contact_point.telegram_push.name

  group_interval  = "5m"
  group_wait      = "30s"
  repeat_interval = "4h"
}
