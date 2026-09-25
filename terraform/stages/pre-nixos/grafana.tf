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
resource "grafana_cloud_access_policy" "logging" {
  provider = grafana.cloud

  region       = grafana_cloud_stack.yinfeng.region_slug
  name         = "logging"
  display_name = "logging"

  scopes = ["metrics:write", "logs:write", "traces:write"]
  realm {
    type       = "org"
    identifier = grafana_cloud_stack.yinfeng.org_id
  }
}
resource "grafana_cloud_access_policy_token" "logging" {
  provider = grafana.cloud

  region           = grafana_cloud_stack.yinfeng.region_slug
  access_policy_id = grafana_cloud_access_policy.logging.policy_id
  name             = "logging"
  display_name     = "Logging Token"
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
  value     = grafana_cloud_access_policy_token.logging.token
  sensitive = true
}

provider "grafana" {
  url  = "https://yinfeng.grafana.net"
  auth = data.sops_file.terraform.data["grafana.stack-token"]
}
resource "grafana_folder" "infrastructure" {
  title = "Infrastructure"
}
resource "grafana_folder" "application" {
  title = "Application"
}
resource "grafana_dashboard" "http_response" {
  config_json = file("${path.module}/../../grafana/dashboards/http-response.json")
  folder      = grafana_folder.infrastructure.uid
}
resource "grafana_dashboard" "system" {
  config_json = file("${path.module}/../../grafana/dashboards/system.json")
  folder      = grafana_folder.infrastructure.uid
}
# The upstream dashboard (garage/script/telemetry/grafana-garage-dashboard-prometheus.json)
# with its metric names adapted to the influx push path: telegraf's prometheus input
# names the field after the metric type, so the series arrive as <metric>_counter /
# <metric>_gauge, and the scrape's job label is replaced by output_bucket.
resource "grafana_dashboard" "garage" {
  config_json = file("${path.module}/../../grafana/dashboards/garage.json")
  folder      = grafana_folder.infrastructure.uid
}
# resource "grafana_dashboard" "minecraft" {
#   config_json = file("${path.module}/../../grafana/dashboards/minecraft.json")
#   folder      = grafana_folder.application.uid
# }
#
locals {
  # Grafana Cloud provisions the stack's own Prometheus datasource
  prometheus_uid = "grafanacloud-prom"
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
    annotations    = {}
    labels         = {}
    is_paused      = false

    data {
      ref_id = "Query"

      relative_time_range {
        from = 60
        to   = 0
      }

      datasource_uid = local.prometheus_uid
      model = jsonencode({
        datasource = {
          type = "prometheus"
          uid  = local.prometheus_uid
        }
        editorMode = "code"
        expr       = "count(systemd_units_active_code{active=\"failed\"}) or vector(0)"
        instant    = true
        range      = false
        refId      = "Query"
      })
    }

    data {
      ref_id = "Value"

      relative_time_range {
        from = 60
        to   = 0
      }

      datasource_uid = "__expr__"
      model = jsonencode({
        datasource = {
          name = "Expression"
          type = "__expr__"
          uid  = "__expr__"
        }
        expression = "Query"
        reducer    = "last"
        refId      = "Value"
        type       = "reduce"
      })
    }

    data {
      ref_id = "Threshold"

      relative_time_range {
        from = 60
        to   = 0
      }

      datasource_uid = "__expr__"
      model = jsonencode({
        conditions = [
          {
            evaluator = {
              params = [0]
              type   = "gt"
            }
          },
        ]
        datasource = {
          name = "Expression"
          type = "__expr__"
          uid  = "__expr__"
        }
        expression = "Value"
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
    annotations    = {}
    labels         = {}
    is_paused      = false

    data {
      ref_id = "Query"

      relative_time_range {
        from = 60
        to   = 0
      }

      datasource_uid = local.prometheus_uid
      model = jsonencode({
        datasource = {
          type = "prometheus"
          uid  = local.prometheus_uid
        }
        editorMode = "code"
        expr       = "count(http_response_result_code != 0) or vector(0)"
        instant    = true
        range      = false
        refId      = "Query"
      })
    }

    data {
      ref_id = "Value"

      relative_time_range {
        from = 60
        to   = 0
      }

      datasource_uid = "__expr__"
      model = jsonencode({
        datasource = {
          name = "Expression"
          type = "__expr__"
          uid  = "__expr__"
        }
        expression = "Query"
        reducer    = "last"
        refId      = "Value"
        type       = "reduce"
      })
    }

    data {
      ref_id = "Threshold"

      relative_time_range {
        from = 60
        to   = 0
      }

      datasource_uid = "__expr__"
      model = jsonencode({
        conditions = [
          {
            evaluator = {
              params = [0]
              type   = "gt"
            }
          },
        ]
        datasource = {
          name = "Expression"
          type = "__expr__"
          uid  = "__expr__"
        }
        expression = "Value"
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
