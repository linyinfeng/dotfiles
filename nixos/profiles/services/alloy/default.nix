{ config, lib, ... }:
let
  inherit (config.lib.self.data)
    loki_username
    loki_host
    influxdb_url
    influxdb_username
    ;
in
{
  services.alloy = {
    enable = true;
    extraFlags = [ ];
    environmentFile = config.sops.templates."alloy-env".path;
  };
  environment.etc."alloy/config.alloy".text = ''
    discovery.relabel "journal" {
      targets = []

      rule {
        source_labels = ["__journal_priority"]
        target_label  = "priority"
      }

      rule {
        source_labels = ["__journal_priority_keyword"]
        target_label  = "level"
      }

      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
      }

      rule {
        source_labels = ["__journal__systemd_user_unit"]
        target_label  = "user_unit"
      }

      rule {
        source_labels = ["__journal__boot_id"]
        target_label  = "boot_id"
      }

      rule {
        source_labels = ["__journal__comm"]
        target_label  = "command"
      }
    }

    loki.source.journal "journal" {
      max_age       = "6h0m0s"
      relabel_rules = discovery.relabel.journal.rules
      forward_to    = [loki.write.default.receiver]
      labels        = {
        host = "parrot",
        job  = "systemd-journal",
      }
    }

    loki.write "default" {
      endpoint {
        url = "https://${loki_host}/loki/api/v1/push"

        basic_auth {
          username = "${loki_username}"
          password = sys.env("LOKI_PASSWORD")
        }
      }
      external_labels = {}
    }
  ''
  + lib.optionalString config.services.garage.enable ''
    // Scraped locally rather than through the influx push path: that path names the
    // field after the metric type (<metric>_counter / <metric>_gauge) and replaces
    // the scrape's `job` label, which no upstream Prometheus dashboard expects.
    prometheus.remote_write "cloud" {
      endpoint {
        url = "${influxdb_url}/api/prom/push"

        basic_auth {
          username = "${toString influxdb_username}"
          password = sys.env("GRAFANA_METRICS_TOKEN")
        }
      }
    }

    prometheus.scrape "garage" {
      // instance is pinned so the series identity does not depend on how we scrape
      targets         = [
        {
          __address__ = "[::1]:${toString config.ports.garage-admin}",
          instance    = "${config.networking.hostName}",
        },
      ]
      job_name        = "garage"
      scrape_interval = "60s"
      bearer_token    = sys.env("GARAGE_METRICS_TOKEN")
      forward_to      = [prometheus.remote_write.cloud.receiver]
    }
  '';
  sops.templates."alloy-env".content = ''
    LOKI_PASSWORD=${config.sops.placeholder."loki_password"}
  ''
  + lib.optionalString config.services.garage.enable ''
    GRAFANA_METRICS_TOKEN=${config.sops.placeholder."influxdb_token"}
    GARAGE_METRICS_TOKEN=${config.sops.placeholder."garage_metrics_token"}
  '';
  sops.secrets = lib.mkMerge [
    {
      loki_password = {
        terraformOutput.enable = true;
        restartUnits = [ "alloy.service" ];
      };
    }
    # the write token and garage's metrics token are only revealed on the hosts that
    # scrape garage; garage_metrics_token itself is declared by the garage profile
    (lib.mkIf config.services.garage.enable {
      influxdb_token = {
        terraformOutput.enable = true;
        restartUnits = [ "alloy.service" ];
      };
      garage_metrics_token.restartUnits = [ "alloy.service" ];
    })
  ];
}
