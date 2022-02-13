{ config, pkgs, lib, ... }:

lib.mkIf
  config.services.xserver.desktopManager.gnome.enable
{
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
  };

  # prevent gdm auto suspend before login
  services.xserver.displayManager.gdm.autoSuspend = false;

  environment.systemPackages = with pkgs; [
    kooha
    pulseaudio
    gnome.gnome-boxes
    gnome.devhelp
    gnome.dconf-editor
    gnome.gnome-sound-recorder
    gnome.gnome-tweaks
    gnome.polari
  ];

  services.gnome.chrome-gnome-shell.enable = true;

  networking.firewall.allowedTCPPorts = [
    5900 # VNC
  ];

  environment.global-persistence.user = {
    directories = [
      ".config/dconf"
      ".config/goa-1.0" # gnome accounts
      ".config/gnome-boxes"
      ".local/share/keyrings"
      ".local/share/Trash"
      ".local/share/webkitgtk" # gnome accounts
      ".local/share/backgrounds"
      ".local/share/gnome-boxes"
      ".cache/tracker3"
    ];
    files = [
      ".face"
      ".config/monitors.xml"
    ];
  };
}
