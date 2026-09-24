{ lib, ... }:
{
  world.profiles.services.restic.enable = lib.mkDefault true;
}
