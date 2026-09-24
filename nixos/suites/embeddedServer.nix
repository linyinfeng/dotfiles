{ lib, ... }:
{
  world.suites.base.enable = lib.mkDefault true;
  world.suites.network.enable = lib.mkDefault true;

  world.profiles.system.types.server.enable = lib.mkDefault true;
  world.profiles.networking.bbr.enable = lib.mkDefault true;
}
