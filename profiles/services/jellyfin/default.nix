{ config, pkgs, lib, ... }:

let
  user = config.services.jellyfin.user;
in
{
  services.jellyfin = {
    enable = true;
  };
  users.users.${user} = {
    shell = pkgs.fish; # for media storage operation
    home = "/var/lib/jellyfin-media";
    createHome = true;
    extraGroups = [
      config.users.groups.transmission.name
    ];
  };

  systemd.services.jellyfin = {
    # faster metadata search
    environment =
      lib.mkIf (config.networking.fw-proxy.enable)
        config.networking.fw-proxy.environment;
  };

  # https://jellyfin.org/docs/general/networking/index.html
  networking.firewall = {
    allowedUDPPorts = [
      # service auto-discovery
      1900
      7359
    ];
  };
}
