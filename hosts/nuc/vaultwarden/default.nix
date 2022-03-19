{ config, pkgs, lib, ... }:

let
  cfg = config.hosts.nuc;
in
{
  services.nginx = {
    virtualHosts = {
      "vault.li7g.com" = {
        forceSSL = true;
        useACMEHost = "nuc.li7g.com";
        listen = config.hosts.nuc.listens;
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
      domain = "https://vault.ts.li7g.com";
      databaseUrl = "postgresql:///vaultwarden";
      signupsAllowed = false;
      sendsAllowed = false;
      emergencyAccessAllowed = false;
      websocketEnabled = true;
      websocketAddress = "127.0.0.1";
      websocketPort = cfg.ports.vaultwarden.websocket;
      rocketAddress = "127.0.0.1";
      rocketPort = cfg.ports.vaultwarden.http;
    };
    environmentFile = config.sops.secrets."vaultwarden".path;
  };
  sops.secrets."vaultwarden".sopsFile = config.sops.secretsDir + /nuc.yaml;

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
