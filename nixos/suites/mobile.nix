{ ... }:
{
  world = {
    profiles = {
      boot.plymouth.enable = true;
      development.shells.enable = true;
      graphical.fonts.enable = true;
      i18n.input-method.enable = true;
      networking.network-manager.enable = true;
      programs = {
        localsend.enable = true;
        tools.enable = true;
      };
      security.hardware-keys.enable = true;
      services = {
        bluetooth.enable = true;
        flatpak.enable = true;
        gnupg.enable = true;
        kde-connect.enable = true;
        pipewire.enable = true;
        printing.enable = true;
        system76-scheduler.enable = true;
      };
      system.types.phone.enable = true;
    };
    suites = {
      base.enable = true;
      network.enable = true;
    };
  };
}
