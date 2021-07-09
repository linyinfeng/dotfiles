{ config, pkgs, lib, ... }:

{
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  services.gnome.chrome-gnome-shell.enable = true;

  security.wrappers.spice-client-glib-usb-acl-helper.source =
    "${pkgs.spice-gtk}/bin/spice-client-glib-usb-acl-helper";

  networking.firewall.allowedTCPPorts = [
    5900 # VNC
  ];

  environment.global-persistence.user.directories = [
    ".local/share/backgrounds"
  ];
}
