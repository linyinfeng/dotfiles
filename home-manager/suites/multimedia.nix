{ lib, ... }:
{
  world.profiles.gnome.enable = lib.mkDefault true;
  world.profiles.niri.enable = lib.mkDefault true;
  world.profiles.darkman.enable = lib.mkDefault true;
  world.profiles.dconf-proxy.enable = lib.mkDefault true;
  world.profiles.browsers.enable = lib.mkDefault true;
  world.profiles.rime.enable = lib.mkDefault true;
  world.profiles.fcitx5.enable = lib.mkDefault true;
  world.profiles.mime.enable = lib.mkDefault true;
  world.profiles.obs-studio.enable = lib.mkDefault true;
  world.profiles.minecraft.enable = lib.mkDefault true;
  world.profiles.desktop-applications.enable = lib.mkDefault true;
}
