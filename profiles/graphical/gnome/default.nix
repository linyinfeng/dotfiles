{ config, pkgs, lib, ... }:

{
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  security.wrappers.spice-client-glib-usb-acl-helper.source =
    "${pkgs.spice-gtk}/bin/spice-client-glib-usb-acl-helper";

  networking.firewall.allowedTCPPorts = [
    5900 # VNC
  ];

  environment.global-persistence.user.directories = [
    "Desktop"
    "Documents"
    "Downloads"
    "Music"
    "Pictures"
    "Public"
    "Templates"
    "Videos"
  ];
}
