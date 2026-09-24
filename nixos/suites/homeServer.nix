{ lib, ... }:
{
  world.suites.server.enable = lib.mkDefault true;

  world.profiles.networking.network-manager.enable = lib.mkDefault true;
}
