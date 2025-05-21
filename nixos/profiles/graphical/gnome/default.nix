{
  config,
  pkgs,
  lib,
  ...
}:
let
  ini = pkgs.formats.ini { };
in
lib.mkIf config.services.xserver.desktopManager.gnome.enable {
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
  };

  # prevent gdm auto suspend before login
  services.xserver.displayManager.gdm.autoSuspend = false;

  environment.systemPackages = with pkgs; [
    kooha
    dconf-editor
    refine
    gnome-sound-recorder
    gnome-power-manager
    gnome-tweaks
  ];

  # TODO wait for text-input-v3 support of chromium and electron applications
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

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
        inherit (config.users.users.gnome-remote-desktop) group;
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
      "${config.users.users.gnome-remote-desktop.home}/.local/share/gnome-remote-desktop/credentials.ini" =
        {
          "L+" = {
            argument = config.sops.templates."gnome-remote-desktop-credentials".path;
            inherit (ownerOptions) user group;
          };
        };
      "${config.users.users.gnome-remote-desktop.home}/.local/share/gnome-remote-desktop/grd.conf" = {
        "L+" = {
          argument = toString (
            ini.generate "grd.conf" {
              RDP = {
                enabled = true;
                tls-key = config.security.acme.tfCerts."li7g_com".key;
                tls-cert = "${config.security.acme.tfCerts."li7g_com".fullChain}";
              };
            }
          );
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
    inherit (config.users.users.gnome-remote-desktop) group;
  };
  sops.secrets."gnome_remote_desktop_password" = {
    terraformOutput.enable = true;
    restartUnits = [ "gnome-remote-desktop.service" ];
  };

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

  security.pam.services = {
    login.fprintAuth = false;
    gdm-fingerprint.text = ''
      auth       required                    pam_shells.so
      auth       requisite                   pam_nologin.so
      auth       requisite                   pam_faillock.so      preauth
      auth       required                    ${pkgs.fprintd}/lib/security/pam_fprintd.so
      auth       optional                    pam_permit.so
      auth       required                    pam_env.so
      auth       [success=ok default=1]      ${pkgs.gdm}/lib/security/pam_gdm.so
      auth       optional                    ${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so

      account    include                     login

      password   required                    pam_deny.so

      session    include                     login
      session    optional                    pam_gnome_keyring.so auto_start
    '';
  };
}
