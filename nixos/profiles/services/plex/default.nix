{
  pkgs,
  config,
  lib,
  ...
}: {
  services.plex = {
    enable = true;
    openFirewall = true;
  };
  users.users.plex = {
    shell = pkgs.fish; # for media storage operation
    home = "/var/lib/plex-media";
    createHome = true;
    extraGroups = [
      config.users.groups.transmission.name
    ];
  };
}
