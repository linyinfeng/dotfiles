{ config, pkgs, lib, osConfig, ... }:
let
  extensionPkgs = with pkgs.gnomeExtensions; [
    gsconnect
    appindicator
    workspace-indicator-2
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
        favorite-apps = lib.mkBefore [
          "org.gnome.Console.desktop"
          "org.gnome.Nautilus.desktop"
          "chromium-browser.desktop"
          "firefox.desktop"
        ];
      };
      "org/gnome/desktop/remote-desktop/rdp" =
        lib.mkIf (osConfig.security.acme.certs ? "main") {
          enable = true;
          tls-cert = "${osConfig.security.acme.certs."main".directory}/cert.pem";
          tls-key = "${osConfig.security.acme.certs."main".directory}/key.pem";
          view-only = false;
        };
      "org/gnome/gnome-session" = {
        auto-save-session = true;
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
