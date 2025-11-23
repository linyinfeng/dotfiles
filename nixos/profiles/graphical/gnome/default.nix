{
  config,
  pkgs,
  lib,
  ...
}:
lib.mkIf config.services.desktopManager.gnome.enable {
  services.displayManager.gdm.enable = true;

  # prevent gdm auto suspend before login
  services.displayManager.gdm.autoSuspend = false;

  environment.systemPackages = with pkgs; [
    kooha
    dconf-editor
    refine
    gnome-sound-recorder
    gnome-power-manager
    gnome-tweaks
    papers
  ];

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  networking.firewall.allowedTCPPorts = [
    3389 # RDP
  ];
  networking.firewall.allowedUDPPorts = [
    config.ports.dns # DNS  server for hotsport
    config.ports.dhcp-server # DHCP server for hotsport
  ];

  environment.global-persistence.user = {
    directories = [
      # ".config/dconf"
      ".config/goa-1.0" # gnome accounts
      ".config/gnome-boxes"
      ".local/share/applications"
      ".local/share/Trash"
      ".local/share/webkitgtk" # gnome accounts
      ".local/share/backgrounds"
      ".local/share/gnome-boxes"
      ".local/share/icc" # user icc files
      ".cache/tracker3"
      ".cache/thumbnails"
    ];
    files = [
      ".face"
      ".config/monitors.xml"
    ];
  };
}
