{ config, lib, ... }:

{
  services.plex = {
    enable = true;
    openFirewall = true;
  };
  users.users.plex.extraGroups = [
    config.users.groups.transmission.name
  ];
}
