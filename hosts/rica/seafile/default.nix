{ config, ... }:

let
  cfg = config.hosts.rica;
in
{
  services.seafile = {
    enable = true;
    adminEmail = "lin.yinfeng@outlook.com";
    initialAdminPassword = "$env(ADMIN_PASSWORD)"; # send by expect script
    ccnetSettings = {
      General.SERVICE_URL = "https://box.li7g.com";
    };
    seafileSettings = {
      fileserver = {
        host = "127.0.0.1";
        port = cfg.ports.seafileFileServer;
      };
      quota.default = 2;
      history.keep_days = 30;
      library_trash.expire_days = 30;
    };
    seahubExtraConf = ''
      SITE_NAME = 'box.li7g.com'
      SITE_TITLE = 'Box'
      FILE_SERVER_ROOT = 'https://box.li7g.com/seafhttp'
    '';
  };

  security.acme.certs."main".extraDomainNames = [
    "box.li7g.com"
    "box.zt.li7g.com"
  ];
  services.nginx.virtualHosts."box.li7g.com" = {
    forceSSL = true;
    useACMEHost = "main";
    serverAliases = [
      "box.zt.li7g.com"
    ];
    locations."/".proxyPass = "http://unix:/run/seahub/gunicorn.sock";
    locations."/seafhttp/" = {
      proxyPass = "http://127.0.0.1:${toString cfg.ports.seafileFileServer}/";
    };
  };

  systemd.services.seahub.serviceConfig.EnvironmentFile = config.sops.templates."seahub-env".path;
  sops.templates."seahub-env".content = ''
    ADMIN_PASSWORD=${config.sops.placeholder."seahub_password"}
  '';
  sops.secrets."seahub_password".sopsFile = config.sops.secretsDir + /terraform/hosts/rica.yaml;
}
