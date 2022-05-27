{ config, lib, ... }:

let
  cfg = config.hosts.rica;
in
{
  options = {
    # TODO add to upstream
    services.grafana.provision.datasources = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options.uid = lib.mkOption {
          type = lib.types.str;
          default = "";
        };
      });
    };
  };
  config = {
    services.nginx = {
      virtualHosts."rica.li7g.com" = {
        locations."/grafana/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.ports.grafana}/";
        };
      };
    };
    services.grafana = {
      addr = "127.0.0.1";
      enable = true;
      port = cfg.ports.grafana;
      rootUrl = "/grafana";
      auth.anonymous.enable = true;
      extraOptions = {
        "SERVER_SERVE_FROM_SUB_PATH" = "true";
        "USERS_DEFAULT_THEME" = "light";
        "DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH" = "${./home.json}";
      };
      security = {
        adminUser = "yinfeng";
        adminPasswordFile =
          config.sops.secrets."grafana/password".path;
      };
    };
    sops.secrets."grafana/password" = {
      owner = config.users.users.grafana.name;
      sopsFile = config.sops.secretsDir + /rica.yaml;
    };
    system.activationScripts.fixGrafanaPermission = {
      deps = [ "users" ];
      text = ''
        dir="${config.environment.global-persistence.root}/var/lib/grafana"
        mkdir -p "$dir"
        chown -R grafana "$dir"
      '';
    };

    systemd.services.grafana.serviceConfig.EnvironmentFile =
      config.sops.templates."grafana-environment".path;
    sops.templates."grafana-environment".content = ''
      INFLUX_TOKEN=${config.sops.placeholder."influxdb/token"}
    '';
    services.grafana.provision = {
      enable = true;
      dashboards = [
        {
          name = "dashboards";
          type = "file";
          options.path = ./dashboards;
        }
      ];
      datasources = [
        {
          name = "InflexDB";
          type = "influxdb";
          url = "https://influxdb.ts.li7g.com";
          uid = "GQCF0Gonz";
          jsonData = {
            version = "Flux";
            organization = "main-org";
            defaultBucket = "main";
          };
          secureJsonData.token = "$INFLUX_TOKEN";
        }
        {
          name = "Loki";
          type = "loki";
          url = "http://localhost:${toString cfg.ports.loki}";
        }
      ];
    };
  };
}
