{ config, pkgs, lib, ... }:

let
  cfg = config.hosts.rica;
in
{
  security.acme.certs."main".extraDomainNames = [
    "vault.li7g.com"
    "vault.ts.li7g.com"
  ];
  services.nginx = {
    virtualHosts = {
      "vault.li7g.com" = {
        forceSSL = true;
        useACMEHost = "main";
        serverAliases = [
          "vault.ts.li7g.com"
        ];
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.ports.vaultwarden.http}";
        };
        locations."/notifications/hub/negotiate" = {
          proxyPass = "http://127.0.0.1:${toString cfg.ports.vaultwarden.http}";
        };
        locations."/notifications/hub" = {
          proxyPass = "http://127.0.0.1:${toString cfg.ports.vaultwarden.websocket}";
          proxyWebsockets = true;
        };
      };
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
      websocketPort = cfg.ports.vaultwarden.websocket;
      rocketAddress = "127.0.0.1";
      rocketPort = cfg.ports.vaultwarden.http;
      smtpHost = "smtp.ts.li7g.com";
      smtpFrom = "vault@li7g.com";
      smtpPort = 465;
      smtpSecurity = "force_tls";
      smtpExplicitTls = true; # workaround for v1.24.0 and before
      smtpUsername = "vault@li7g.com";
    };
    environmentFile = config.sops.templates."vaultwarden-env".path;
  };
  sops.templates."vaultwarden-env".content = ''
    ADMIN_TOKEN=${config.sops.placeholder."vaultwarden/admin-token"}
    SMTP_PASSWORD=${config.sops.placeholder."mail/password"}
  '';
  sops.secrets."vaultwarden/admin-token".sopsFile = config.sops.secretsDir + /rica.yaml;

  services.postgresql.ensureDatabases = [ "vaultwarden" ];
  services.postgresql.ensureUsers = [
    {
      name = "vaultwarden";
      ensurePermissions = {
        "DATABASE vaultwarden" = "ALL PRIVILEGES";
      };
    }
  ];
}
