{ config, lib, ... }:

{
  services.mastodon = {
    enable = true;
    enableUnixSocket = true;
    database = {
      host = "/run/postgresql";
      name = "mastodon";
      user = "mastodon";
    };
    mediaAutoRemove = {
      enable = true;
      olderThanDays = 60;
      startAt = "daily";
    };
    smtp = {
      authenticate = true;
      host = "smtp.li7g.com";
      port = config.ports.smtp-starttls;
      user = "mastodon@li7g.com";
      fromAddress = "mastodon@li7g.com";
      # type is null or path, add a leading /
      passwordFile = "/$CREDENTIALS_DIRECTORY/mail-password";
    };
    localDomain = "li7g.com";
    configureNginx = false;
    extraConfig = {
      WEB_DOMAIN = "mastodon.li7g.com";
      ALTERNATE_DOMAINS = lib.concatStringsSep "," [
        "mastodon.ts.li7g.com"
        "mastodon.zt.li7g.com"
        "social.li7g.com"
        "social.ts.li7g.com"
        "social.zt.li7g.com"
      ];
    };
  };
  systemd.services.mastodon-init-dirs.serviceConfig.LoadCredential = [
    "mail-password:${config.sops.secrets."mail_password".path}"
  ];
  services.nginx.virtualHosts."mastodon.*" = {
    forceSSL = true;
    useACMEHost = "main";
    serverAliases = [ "social.*" ];
    root = "${config.services.mastodon.package}/public/";
    locations."/system/".alias = "/var/lib/mastodon/public-system/";
    locations."/" = {
      tryFiles = "$uri @proxy";
    };
    locations."@proxy" = {
      proxyPass = "http://unix:/run/mastodon-web/web.socket";
      proxyWebsockets = true;
    };
    locations."/api/v1/streaming/" = {
      proxyPass = "http://unix:/run/mastodon-streaming/streaming.socket";
      proxyWebsockets = true;
    };
  };
  systemd.services.nginx.serviceConfig.SupplementaryGroups = [
    config.services.mastodon.group
  ];
  services.postgresql.ensureDatabases = [ "mastodon" ];
  services.postgresql.ensureUsers = [
    {
      name = "mastodon";
      ensurePermissions = {
        "DATABASE mastodon" = "ALL PRIVILEGES";
      };
    }
  ];
  sops.secrets."mail_password" = {
    sopsFile = config.sops.secretsDir + /terraform/common.yaml;
    restartUnits = [ "mastodon-init-dirs.service" ];
  };
}
