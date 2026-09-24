{ lib, ... }:
{
  world.profiles.hledger.enable = lib.mkDefault true;
}
