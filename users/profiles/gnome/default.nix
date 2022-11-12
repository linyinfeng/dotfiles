{ config, pkgs, lib, osConfig, ... }:
let
  extensionPkgs = with pkgs.gnomeExtensions; [
    gsconnect
    appindicator
    workspace-indicator-2
    dash-to-dock
  ];
in
lib.mkIf osConfig.services.xserver.desktopManager.gnome.enable
{
  home.packages = extensionPkgs;

  programs.chromium.extensions = [
    "gphhapmejobijbbhgpjhcjognlahblep" # GNOME Shell integration
    "jfnifeihccihocjbfcfhicmmgpjicaec" # GSConnect
  ];

  # Remove initial setup dialog
  home.file.".config/gnome-initial-setup-done".text = "yes";

  dconf.settings = lib.mkMerge [
    {
      # Do not sleep when ac power connected
      "org/gnome/settings-daemon/plugins/power" = {
        sleep-inactive-ac-type = "nothing";
      };
      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = map (p: p.extensionUuid) extensionPkgs;
        disabled-extensions = [ ];
        favorite-apps = lib.mkBefore [
          "org.gnome.Console.desktop"
          "org.gnome.Nautilus.desktop"
          "chromium-browser.desktop"
          "firefox.desktop"
          "gnome-system-monitor.desktop"
          "code.desktop"
        ];
      };
      "org/gnome/desktop/interface" = {
        clock-show-weekday = true;
        show-battery-percentage = true;
        locate-pointer = true;
      };
      # just use the standard touchpad and mouse speed
      "org/gnome/desktop/peripherals/mouse" = {
        speed = 0;
      };
      "org/gnome/desktop/peripherals/touchpad" = {
        speed = 0;
        natural-scroll = true;
        tap-to-click = true;
      };
      "org/gnome/desktop/remote-desktop/rdp" =
        lib.mkIf (osConfig.security.acme.certs ? "main") {
          enable = true;
          tls-cert = "${osConfig.security.acme.certs."main".directory}/cert.pem";
          tls-key = "${osConfig.security.acme.certs."main".directory}/key.pem";
          view-only = false;
        };
      "org/gnome/desktop/calendar" = {
        show-weekdate = true;
      };
      "org/gnome/shell/extensions/dash-to-dock" =
        {
          apply-custom-theme = true;
          custom-theme-shrink = true;
          dash-max-icon-size = 32;
          show-mounts = false;
          scroll-action = "switch-workspace";
          intellihide-mode = "ALL_WINDOWS";
          show-dock-urgent-notify = false;
        };
    }
    (
      let
        proxy = {
          host = "localhost";
          port = osConfig.networking.fw-proxy.mixinConfig.mixed-port;
        };
      in
      lib.mkIf (osConfig.networking.fw-proxy.enable) {
        "system/proxy" = {
          mode = "manual";
          use-same-proxy = true;
        };
        "system/proxy/http" = proxy;
        "system/proxy/https" = proxy;
        "system/proxy/socks" = proxy;
      }
    )
  ];

  home.activation.allowGdmReadFace = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.acl}/bin/setfacl --modify=group:gdm:--x "$HOME"
  '';

  # gsconnect association
  xdg.mimeApps.associations.added = {
    "x-scheme-handler/sms" = "org.gnome.Shell.Extensions.GSConnect.desktop";
    "x-scheme-handler/tel" = "org.gnome.Shell.Extensions.GSConnect.desktop";
  };

  home.global-persistence.directories = [
    ".config/gsconnect"
  ];
}
