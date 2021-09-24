{ config, pkgs, lib, ... }:

{
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  environment.systemPackages = with pkgs; [
    kooha
    pulseaudio
    gnome.devhelp
  ];

  services.gnome.chrome-gnome-shell.enable = true;

  networking.firewall.allowedTCPPorts = [
    5900 # VNC
  ];

  environment.global-persistence.user = {
    directories = [
      ".config/dconf"
      ".config/goa-1.0" # gnome accounts
      ".local/share/keyrings"
      ".local/share/Trash"
      ".local/share/webkitgtk" # gnome accounts
      ".local/share/backgrounds"
      ".cache/tracker3"
    ];
    files = [
      ".face"
      ".config/mimeapps.list"
    ];
  };
}
