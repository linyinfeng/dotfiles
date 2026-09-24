{ lib, ... }:
{
  world.profiles.graphical.gnome.enable = lib.mkDefault true;
  world.profiles.graphical.kde.enable = lib.mkDefault true;
  world.profiles.graphical.niri.enable = lib.mkDefault true;
  world.profiles.graphical.fonts.enable = lib.mkDefault true;
  world.profiles.graphical.activate-linux.enable = lib.mkDefault true;
  world.profiles.i18n.input-method.enable = lib.mkDefault true;
  world.profiles.services.gnome-keyring.enable = lib.mkDefault true;
  world.profiles.services.pipewire.enable = lib.mkDefault true;
}
