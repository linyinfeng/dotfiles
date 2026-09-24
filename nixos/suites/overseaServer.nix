{ lib, ... }:
{
  world.suites.server.enable = lib.mkDefault true;

  world.profiles.services.bind.enable = lib.mkDefault true;
}
