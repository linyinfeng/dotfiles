{ config, lib, ... }:

let
  cfg = config.hosts.rica;
in
{
  security.acme.certs."main".extraDomainNames = [
    "grafana.li7g.com"
  ];
  services.nginx.virtualHosts."grafana.li7g.com" = {
    forceSSL = true;
    useACMEHost = "main";
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString cfg.ports.grafana}/";
    };
  };
  services.grafana = {
    addr = "127.0.0.1";
    enable = true;
    port = cfg.ports.grafana;
    rootUrl = "https://grafana.li7g.com";
    auth.anonymous.enable = true;
    extraOptions = {
      "SERVER_SERVE_FROM_SUB_PATH" = "true";
      "USERS_DEFAULT_THEME" = "light";
      "DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH" = "${./home.json}";
      "SMTP_STARTTLS_POLICY" = "true";
    };
    security = {
      adminUser = "yinfeng";
      adminPasswordFile =
        config.sops.secrets."grafana/password".path;
    };
    smtp = {
      enable = true;
      fromAddress = "grafana@li7g.com";
      user = "grafana@li7g.com";
      host = "smtp.zt.li7g.com:587";
    };
    database = {
      type = "postgres";
      host = "/run/postgresql";
      name = "grafana";
      user = "grafana";
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
  systemd.services.grafana.serviceConfig.EnvironmentFile = [
    config.sops.templates."grafana-environment".path
  ];
  sops.templates."grafana-environment".content = ''
    INFLUX_TOKEN=${config.sops.placeholder."influxdb/token"}
    LOKI_PASSWORD=${config.sops.placeholder."loki_password"}
    GF_SMTP_PASSWORD=${config.sops.placeholder."mail/password"}
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
        url = "https://influxdb.li7g.com";
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
        url = "https://loki.li7g.com";
        basicAuth = true;
        basicAuthUser = "loki";
        secureJsonData.basicAuthPassword = "$LOKI_PASSWORD";
      }
    ];
  };

  sops.secrets."grafana/password" = {
    owner = config.users.users.grafana.name;
    sopsFile = config.sops.secretsDir + /hosts/rica.yaml;
    restartUnits = [ "grafana.service" ];
  };
  sops.secrets."mail/password" = {
    sopsFile = config.sops.secretsDir + /common.yaml;
    restartUnits = [ "grafana.service" ];
  };
  sops.secrets."loki_password" = {
    sopsFile = config.sops.secretsDir + /terraform/infrastructure.yaml;
    restartUnits = [ "grafana.service" ];
  };
}
