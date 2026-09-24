{ lib, ... }:
{
  world.suites.base.enable = lib.mkDefault true;
  world.suites.security.enable = lib.mkDefault true;
  world.suites.other.enable = lib.mkDefault true;

  world.profiles.dconf-proxy.enable = lib.mkDefault true;
  world.profiles.browsers.enable = lib.mkDefault true;
  world.profiles.rime.enable = lib.mkDefault true;
  world.profiles.mime.enable = lib.mkDefault true;
  world.profiles.git.enable = lib.mkDefault true;
  world.profiles.development.enable = lib.mkDefault true;
  world.profiles.ssh.enable = lib.mkDefault true;
  world.profiles.shells.enable = lib.mkDefault true;
  world.profiles.xdg-dirs.enable = lib.mkDefault true;
}
