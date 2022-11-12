{ config, lib, ... }:

{
  services.mastodon = {
    enable = true;
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
      host = "smtp.zt.li7g.com";
      port = 587;
      user = "mastodon@li7g.com";
      fromAddress = "mastodon@li7g.com";
      passwordFile = "$CREDENTIALS_DIRECTORY/mail-password";
    };
    localDomain = "mastodon.li7g.com";
    configureNginx = true;
  };
  systemd.services.mastodon-init-dirs.serviceConfig.LoadCredential = [
    "mail-password:${config.sops.secrets."mail_password".path}"
  ];
  services.nginx.virtualHosts."mastodon.*" = {
    enableACME = lib.mkForce false;
    useACMEHost = "main";
  };
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
