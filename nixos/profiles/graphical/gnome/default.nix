{
  config,
  pkgs,
  lib,
  ...
}:
lib.mkIf config.services.xserver.desktopManager.gnome.enable {
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
  };

  # prevent gdm auto suspend before login
  services.xserver.displayManager.gdm.autoSuspend = false;

  environment.systemPackages = with pkgs; [
    kooha
    gnome.dconf-editor
    gnome.gnome-sound-recorder
    gnome.gnome-power-manager
    gnome.gnome-tweaks
  ];

  # disabled
  # install extensions declaratively with home-manager dconf options
  services.gnome.gnome-browser-connector.enable = false;

  # manually enable remote desktop service
  systemd.services.gnome-remote-desktop.wantedBy = [ "graphical.target" ];
  # acme certificates and credentials
  systemd.tmpfiles.settings."80-gnome-remote-desktop" =
    let
      ownerOptions = {
        user = config.users.users.gnome-remote-desktop.name;
        group = config.users.users.gnome-remote-desktop.group;
      };
    in
    {
      ${config.users.users.gnome-remote-desktop.home} = {
        "d" = {
          mode = "0700";
          inherit (ownerOptions) user group;
        };
        "Z" = {
          inherit (ownerOptions) user group;
        };
      };
      "${config.users.users.gnome-remote-desktop.home}/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt" = {
        "L+" = {
          argument = "${config.security.acme.tfCerts."li7g_com".fullChain}";
          inherit (ownerOptions) user group;
        };
      };
      "${config.users.users.gnome-remote-desktop.home}/.local/share/gnome-remote-desktop/certificates/rdp-tls.key" = {
        "L+" = {
          argument = config.security.acme.tfCerts."li7g_com".key;
          inherit (ownerOptions) user group;
        };
      };
      "${config.users.users.gnome-remote-desktop.home}/.local/share/gnome-remote-desktop/credentials.ini" = {
        "L+" = {
          argument = config.sops.templates."gnome-remote-desktop-credentials".path;
          inherit (ownerOptions) user group;
        };
      };
    };
  users.users.gnome-remote-desktop.extraGroups = [ config.users.groups.acmetf.name ];
  sops.templates."gnome-remote-desktop-credentials" = {
    content =
      let
        password = config.sops.placeholder."gnome_remote_desktop_password";
      in
      ''
        [RDP]
        credentials={'username': <'grd'>, 'password': <'${password}'>}
      '';
    owner = config.users.users.gnome-remote-desktop.name;
    group = config.users.users.gnome-remote-desktop.group;
  };
  sops.secrets."gnome_remote_desktop_password" = {
    terraformOutput.enable = true;
    restartUnits = [ "gnome-remote-desktop.service" ];
  };

  networking.firewall.allowedTCPPorts = [
    3389 # RDP
  ];
  networking.firewall.allowedUDPPorts = [
    53 # DNS  server for hotsport
    67 # DHCP server for hotsport
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
