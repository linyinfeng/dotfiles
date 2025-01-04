{ config, ... }:
{
  services.nginx.virtualHosts."vault.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.ports.vaultwarden-http}";
    };
    locations."/notifications/hub/negotiate" = {
      proxyPass = "http://127.0.0.1:${toString config.ports.vaultwarden-http}";
    };
    locations."/notifications/hub" = {
      proxyPass = "http://127.0.0.1:${toString config.ports.vaultwarden-websocket}";
      proxyWebsockets = true;
    };
  };
  services.vaultwarden = {
    enable = true;
    dbBackend = "postgresql";
    config = {
      domain = "https://vault.li7g.com";
      databaseUrl = "postgresql:///vaultwarden";
      signupsAllowed = false;
      emergencyAccessAllowed = false;
      websocketEnabled = true;
      websocketAddress = "127.0.0.1";
      websocketPort = config.ports.vaultwarden-websocket;
      rocketAddress = "127.0.0.1";
      rocketPort = config.ports.vaultwarden-http;
      smtpHost = "smtp.li7g.com";
      smtpFrom = "vault@li7g.com";
      smtpPort = config.ports.smtp-starttls;
      smtpSecurity = "starttls";
      smtpUsername = "vault@li7g.com";
    };
    environmentFile = config.sops.templates."vaultwarden-env".path;
  };
  sops.templates."vaultwarden-env".content = ''
    ADMIN_TOKEN=${config.sops.placeholder."vaultwarden_admin_token"}
    SMTP_PASSWORD=${config.sops.placeholder."mail_password"}
  '';
  sops.secrets."vaultwarden_admin_token" = {
    terraformOutput.enable = true;
    restartUnits = [ "vaultwarden.service" ];
  };
  sops.secrets."mail_password" = {
    terraformOutput.enable = true;
    restartUnits = [ "vaultwarden.service" ];
  };

  services.postgresql.ensureDatabases = [ "vaultwarden" ];
  services.postgresql.ensureUsers = [
    {
      name = "vaultwarden";
      ensureDBOwnership = true;
    }
  ];
  systemd.services.vaultwarden = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };

  services.restic.backups.b2.paths = [
    "/var/lib/vaultwarden"
  ];
}
