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
      host = "smtp.li7g.com";
      port = config.ports.smtp-starttls;
      user = "mastodon@li7g.com";
      fromAddress = "mastodon@li7g.com";
      # type is null or path, add a leading /
      passwordFile = "/$CREDENTIALS_DIRECTORY/mail-password";
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
