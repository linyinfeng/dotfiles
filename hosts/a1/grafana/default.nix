{ config, lib, ... }:

{
  services.nginx.virtualHosts."grafana.*" = {
    forceSSL = true;
    useACMEHost = "main";
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.ports.grafana}/";
    };
  };
  services.grafana = {
    enable = true;
    settings = {
      server = {
        root_url = "https://grafana.li7g.com";
        http_addr = "127.0.0.1";
        http_port = config.ports.grafana;
      };
      "auth.anonymous".enabled = true;
      users.default_theme = "light";
      dashboards.default_home_dashboard_path = "${./dashboards/home.json}";
      smtp = {
        enabled = true;
        from_address = "grafana@li7g.com";
        user = "grafana@li7g.com";
        host = "smtp.li7g.com:${toString config.ports.smtp-starttls}";
        startTLS_policy = "MandatoryStartTLS";
      };
      security = {
        admin_user = "yinfeng";
        admin_password = "$__env{GRAFANA_PASSWORD}";
      };
      database = {
        type = "postgres";
        host = "/run/postgresql";
        name = "grafana";
        user = "grafana";
      };
    };
    declarativePlugins = [ ];
  };
  services.postgresql.ensureDatabases = [ "grafana" ];
  services.postgresql.ensureUsers = [
    {
      name = "grafana";
      ensurePermissions = {
        "DATABASE grafana" = "ALL PRIVILEGES";
      };
    }
  ];
  systemd.services.grafana = {
    serviceConfig.EnvironmentFile = [
      config.sops.templates."grafana-environment".path
    ];
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };
  sops.templates."grafana-environment".content = ''
    GRAFANA_PASSWORD=${config.sops.placeholder."grafana_password"}
    INFLUX_TOKEN=${config.sops.placeholder."influxdb_token"}
    LOKI_PASSWORD=${config.sops.placeholder."loki_password"}
    GF_SMTP_PASSWORD=${config.sops.placeholder."mail_password"}
    ALERTMANAGER_PASSWORD=${config.sops.placeholder."alertmanager_password"}
  '';
  services.grafana.provision = {
    enable = true;
    dashboards.settings = {
      providers = [
        {
          name = "dashboards";
          type = "file";
          options.path = ./dashboards;
        }
      ];
    };
    datasources.settings = {
      datasources = [
        {
          uid = "influxdb-li7g-com";
          name = "InflexDB";
          type = "influxdb";
          url = "https://influxdb.ts.li7g.com";
          jsonData = {
            version = "Flux";
            organization = "main-org";
            defaultBucket = "main";
          };
          secureJsonData.token = "$__env{INFLUX_TOKEN}";
        }
        {
          uid = "loki-li7g-com";
          name = "Loki";
          type = "loki";
          url = "https://loki.ts.li7g.com";
          basicAuth = true;
          basicAuthUser = "loki";
          secureJsonData.basicAuthPassword = "$__env{LOKI_PASSWORD}";
          jsonData = {
            alertmanagerUid = "alertmanager-li7g-com";
          };
        }
        {
          uid = "alertmanager-li7g-com";
          name = "Alertmanager";
          type = "alertmanager";
          url = "https://alertmanager.ts.li7g.com";
          basicAuth = true;
          basicAuthUser = "alertmanager";
          secureJsonData.basicAuthPassword = "$__env{ALERTMANAGER_PASSWORD}";
          jsonData = {
            handleGrafanaManagedAlerts = true;
            implementation = "prometheus";
          };
        }
      ];
    };
  };

  sops.secrets."grafana_password" = {
    sopsFile = config.sops-file.terraform;
    restartUnits = [ "grafana.service" ];
  };
  sops.secrets."mail_password" = {
    sopsFile = config.sops-file.get "terraform/common.yaml";
    restartUnits = [ "grafana.service" ];
  };
  sops.secrets."loki_password" = {
    sopsFile = config.sops-file.get "terraform/infrastructure.yaml";
    restartUnits = [ "grafana.service" ];
  };
  sops.secrets."alertmanager_password" = {
    sopsFile = config.sops-file.get "terraform/infrastructure.yaml";
    restartUnits = [ "grafana.service" ];
  };
}