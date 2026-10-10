{ config, lib, ... }:
{
  services.ncro = {
    enable = true;
    settings = {
      server.listen = "[::1]:${toString config.ports.ncro}";
      logging.timestamps = false;
    };
  };
  systemd.services.ncro.environment = lib.mkIf config.networking.fw-proxy.enable config.networking.fw-proxy.environment;
  services.ncro.settings.upstreams = [
    {
      url = "https://cache.nixos.org";
      priority = 10; # lower = preferred on latency ties (within 10%)
      public_key = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
    }
    {
      url = "https://cache.li7g.com";
      priority = 30;
      public_key = "cache.li7g.com:YIVuYf8AjnOc5oncjClmtM19RaAZfOKLFFyZUpOrfqM=";
    }
  ];
  nix.settings.substituters = lib.mkForce [ "http://[::1]:${toString config.ports.ncro}" ];
}
