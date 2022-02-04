{ config, pkgs, lib, ... }:

let
  cfg = config.hosts.nuc;
in
{
  services.nginx = {
    virtualHosts = {
      "vault.li7g.com" = {
        serverName = "vault.li7g.com vault.ts.li7g.com";
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.ports.vaultwarden.http}/";
        };
        locations."/notifications/hub/negotiate" = {
          proxyPass = "http://127.0.0.1:${toString cfg.ports.vaultwarden.http}/";
        };
        locations."/notifications/hub" = {
          proxyPass = "http://127.0.0.1:${toString cfg.ports.vaultwarden.websocket}/";
          proxyWebsockets = true;
        };
      };
    };
  };
  services.vaultwarden = {
    enable = true;
    backupDir = "/media/data/vaultwarden-backup";
    config = {
      domain = "https://vault.li7g.com";
      signupsAllowed = false;
      sendsAllowed = false;
      emergencyAccessAllowed = false;
      websocketEnabled = true;
      websocketAddress = "127.0.0.1";
      websocketPort = cfg.ports.vaultwarden.websocket;
      rocketAddress = "127.0.0.1";
      rocketPort = cfg.ports.vaultwarden.http;
    };
    environmentFile = config.sops.secrets.vaultwarden.path;
  };
  sops.secrets.vaultwarden = { };
  systemd.services.backup-vaultwarden.aliases = lib.mkForce [ ];
  systemd.timers.backup-vaultwarden.aliases = lib.mkForce [ ];
}
