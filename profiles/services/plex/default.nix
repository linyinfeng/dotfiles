{ pkgs, config, lib, ... }:

{
  services.plex = {
    enable = true;
    openFirewall = true;
  };
  users.users.plex = {
    shell = pkgs.fish; # for media storage operation
    extraGroups = [
      config.users.groups.transmission.name
    ];
  };
}
