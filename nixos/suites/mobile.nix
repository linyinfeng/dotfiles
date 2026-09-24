{ lib, ... }:
{
  world.suites.base.enable = lib.mkDefault true;
  world.suites.network.enable = lib.mkDefault true;

  world.profiles.boot.plymouth.enable = lib.mkDefault true;
  world.profiles.system.types.phone.enable = lib.mkDefault true;
  world.profiles.graphical.fonts.enable = lib.mkDefault true;
  world.profiles.i18n.input-method.enable = lib.mkDefault true;
  world.profiles.programs.tools.enable = lib.mkDefault true;
  world.profiles.programs.localsend.enable = lib.mkDefault true;
  world.profiles.development.shells.enable = lib.mkDefault true;
  world.profiles.services.flatpak.enable = lib.mkDefault true;
  world.profiles.services.gnupg.enable = lib.mkDefault true;
  world.profiles.services.pipewire.enable = lib.mkDefault true;
  world.profiles.services.kde-connect.enable = lib.mkDefault true;
  world.profiles.services.printing.enable = lib.mkDefault true;
  world.profiles.services.bluetooth.enable = lib.mkDefault true;
  world.profiles.security.hardware-keys.enable = lib.mkDefault true;
  world.profiles.services.system76-scheduler.enable = lib.mkDefault true;
  world.profiles.networking.network-manager.enable = lib.mkDefault true;
}
