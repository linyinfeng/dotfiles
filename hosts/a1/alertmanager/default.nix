{ config, ... }:

{
  services.prometheus.alertmanager = {
    enable = true;
    port = config.ports.alertmanager;
    logLevel = "info";
    environmentFile = config.sops.templates."alertmanager-env".path;
    configuration = {
      global = {
        smtp_smarthost = "smtp.li7g.com:${toString config.ports.smtp-starttls}";
        smtp_from = "alertmanager@li7g.com";
        smtp_auth_username = "alertmanager@li7g.com";
        smtp_auth_password = "$SMTP_AUTH_PASSWORD";
        smtp_require_tls = true;
        http_config = {
          basic_auth = {
            username = "alertmanager";
            password = "$HTTP_PASSWORD";
          };
        };
      };
      receivers = [
        {
          name = "linyinfeng";
          email_configs = [
            { to = "lin.yinfeng@outlook.com"; }
          ];
        }
      ];
      route = {
        receiver = "linyinfeng";
        group_by = [ "host" ];
      };
    };
    extraFlags = [
      "--web.config.file \"\${CREDENTIALS_DIRECTORY}/web-config\""
      ''--web.external-url="https://alertmanager.li7g.com"''
    ];
  };
  systemd.services.alertmanager.serviceConfig.LoadCredential = [
    "web-config:${config.sops.templates."alertmanager-web-config".path}"
  ];
  sops.templates."alertmanager-web-config".content = builtins.toJSON {
    basic_auth_users = {
      alertmanager = "${config.sops.placeholder."alertmanager_hashed_password"}";
    };
  };

  services.nginx = {
    virtualHosts."alertmanager.*" = {
      forceSSL = true;
      useACMEHost = "main";
      locations."/".proxyPass = "http://localhost:${toString config.ports.alertmanager}";
    };
  };
  sops.templates."alertmanager-env".content = ''
    SMTP_AUTH_PASSWORD=${config.sops.placeholder."mail_password"}
    HTTP_PASSWORD=${config.sops.placeholder."alertmanager_password"}
  '';
  sops.secrets."mail_password" = {
    sopsFile = config.sops-file.get "terraform/common.yaml";
    restartUnits = [ "alertmanager.service" ];
  };
  sops.secrets."alertmanager_password" = {
    sopsFile = config.sops-file.get "terraform/infrastructure.yaml";
    restartUnits = [ "alertmanager.service" ];
  };
  sops.secrets."alertmanager_hashed_password" = {
    sopsFile = config.sops-file.terraform;
    restartUnits = [ "alertmanager.service" ];
  };
}