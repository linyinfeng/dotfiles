{
  config,
  pkgs,
  lib,
  ...
}:
lib.mkIf
config.services.xserver.desktopManager.gnome.enable
{
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
  };

  boot.plymouth.enable = true;

  # prevent gdm auto suspend before login
  services.xserver.displayManager.gdm.autoSuspend = false;

  environment.systemPackages = with pkgs; [
    kooha
    pulseaudio
    gnome.gnome-boxes
    gnome.devhelp
    gnome.dconf-editor
    gnome.gnome-sound-recorder
    gnome.gnome-power-manager
    gnome.gnome-tweaks
    gnome.gnome-remote-desktop
    gnome.polari
  ];

  services.gnome.gnome-browser-connector.enable = true;

  networking.firewall.allowedTCPPorts = [
    3389 # RDP
    # 5900 # VNC
  ];
  networking.firewall.allowedUDPPorts = [
    53 # DNS  server for hotsport
    67 # DHCP server for hotsport
    3389 # RDP
  ];

  environment.global-persistence.user = {
    directories = [
      # ".config/dconf"
      ".config/goa-1.0" # gnome accounts
      ".config/gnome-boxes"
      ".local/share/keyrings"
      ".local/share/applications"
      ".local/share/Trash"
      ".local/share/webkitgtk" # gnome accounts
      ".local/share/backgrounds"
      ".local/share/gnome-boxes"
      ".cache/tracker3"
      ".cache/thumbnails"
    ];
    files = [
      ".face"
      ".config/monitors.xml"
    ];
  };

  security.pam.services = {
    gdm-password.text = lib.mkForce ''
      auth     requisite      pam_nologin.so
      auth     required       pam_succeed_if.so uid >= 1000 quiet
      auth     optional       pam_unix.so nullok likeauth
      auth     optional       ${pkgs.gnome.gnome-keyring}/lib/security/pam_gnome_keyring.so
      auth     sufficient     pam_unix.so nullok likeauth try_first_pass
      auth     required       pam_deny.so

      account  include        login
      password substack       login

      session  optional       pam_keyinit.so revoke
      session  include        login
    '';
    gdm-fingerprint.text = ''
      auth     requisite      pam_nologin.so
      auth     required       pam_succeed_if.so uid >= 1000 quiet
      auth     required       ${pkgs.fprintd}/lib/security/pam_fprintd.so
      auth     optional       ${pkgs.gnome.gnome-keyring}/lib/security/pam_gnome_keyring.so

      account  include        login
      password required       ${pkgs.fprintd}/lib/security/pam_fprintd.so

      session  optional       pam_keyinit.so revoke
      session  include        login
    '';
  };
}