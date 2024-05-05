{ config, ... }:
let
  inherit (config.lib.self.data) loki_username loki_host;
in
{
  services.promtail = {
    enable = true;
    extraFlags = [ "-config.expand-env=true" ];
    configuration = {
      server = {
        http_listen_port = 0;
        grpc_listen_port = 0;
      };
      positions.filename = "/tmp/positions.yaml";
      clients = [
        {
          url = "https://${loki_host}/api/prom/push";
          basic_auth = {
            username = loki_username;
            password = "\${LOKI_PASSWORD}";
          };
        }
      ];
      scrape_configs = [
        {
          job_name = "journal";
          journal = {
            max_age = "6h";
            labels = {
              job = "systemd-journal";
              host = config.networking.hostName;
            };
          };
          relabel_configs = [
            {
              source_labels = [ "__journal_priority" ];
              target_label = "priority";
            }
            {
              source_labels = [ "__journal_priority_keyword" ];
              target_label = "level";
            }
            {
              source_labels = [ "__journal__systemd_unit" ];
              target_label = "unit";
            }
            {
              source_labels = [ "__journal__systemd_user_unit" ];
              target_label = "user_unit";
            }
            {
              source_labels = [ "__journal__boot_id" ];
              target_label = "boot_id";
            }
            {
              source_labels = [ "__journal__comm" ];
              target_label = "command";
            }
          ];
        }
      ];
    };
  };
  systemd.services.promtail.serviceConfig.EnvironmentFile = [
    config.sops.templates."promtail-env".path
  ];
  sops.templates."promtail-env".content = ''
    LOKI_PASSWORD=${config.sops.placeholder."loki_password"}
  '';
  sops.secrets."loki_password" = {
    terraformOutput.enable = true;
    restartUnits = [ "promtail.service" ];
  };
}
