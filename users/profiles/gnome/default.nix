{ config, pkgs, lib, osConfig, ... }:
let
  extensionPkgs = with pkgs.gnomeExtensions; [
    # arc-menu
    gsconnect
    dash-to-dock
    # dash-to-panel
    appindicator
    # caffeine
    gtile
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
