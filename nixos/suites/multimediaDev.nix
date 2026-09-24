{ lib, ... }:
{
  world.suites.multimedia.enable = lib.mkDefault true;
  world.suites.development.enable = lib.mkDefault true;

  world.profiles.development.ides.enable = lib.mkDefault true;
}
