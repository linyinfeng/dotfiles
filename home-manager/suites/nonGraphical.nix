{ lib, ... }:
{
  world.suites.base.enable = lib.mkDefault true;
  world.suites.development.enable = lib.mkDefault true;
  world.suites.virtualization.enable = lib.mkDefault true;
  world.suites.synchronize.enable = lib.mkDefault true;
  world.suites.security.enable = lib.mkDefault true;
  world.suites.other.enable = lib.mkDefault true;
}
