{ lib, ... }:
{
  world.suites.base.enable = lib.mkDefault true;
  world.suites.multimediaDev.enable = lib.mkDefault true;
  world.suites.music.enable = lib.mkDefault true;
  world.suites.design.enable = lib.mkDefault true;
  world.suites.virtualization.enable = lib.mkDefault true;
  world.suites.synchronize.enable = lib.mkDefault true;
  world.suites.security.enable = lib.mkDefault true;
  world.suites.other.enable = lib.mkDefault true;
}
