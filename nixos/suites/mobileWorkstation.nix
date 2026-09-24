{ lib, ... }:
{
  world.suites.workstation.enable = lib.mkDefault true;

  world.profiles.networking.behind-fw.enable = lib.mkDefault true;
  world.profiles.networking.fw-proxy.enable = lib.mkDefault true;
  world.profiles.graphical.graphical-powersave-target.enable = lib.mkDefault true;
}
