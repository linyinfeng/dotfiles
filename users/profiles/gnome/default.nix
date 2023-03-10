{ config, pkgs, lib, osConfig, ... }:
let
  extensionPkgs = with pkgs.gnomeExtensions; [
    gsconnect
    appindicator
    dash-to-dock
    clipboard-history
    ibus-tweaker
  ];
  inherit (lib.hm.gvariant) mkArray mkTuple mkString mkUint32 type;
in
lib.mkIf osConfig.services.xserver.desktopManager.gnome.enable
{
  home.packages = extensionPkgs ++ (with pkgs; [
    blackbox-terminal
  ]);

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
          "com.raggesilver.BlackBox.desktop"
          "org.gnome.Nautilus.desktop"
          "firefox.desktop"
          "gnome-system-monitor.desktop"
          "code.desktop"
        ];
        welcome-dialog-last-shown-version = "43.1";
      };
      "org/gnome/desktop/interface" = {
        clock-show-weekday = true;
        show-battery-percentage = true;
        locate-pointer = true;
      };
      "org/gnome/desktop/input-sources" = {
        sources =
          mkArray (type.tupleOf [ type.string type.string ]) [
            (mkTuple [ (mkString "xkb") (mkString "us") ])
            (mkTuple [ (mkString "ibus") (mkString "rime") ])
            (mkTuple [ (mkString "ibus") (mkString "mozc-jp") ])
          ];
      };
      "org/gnome/desktop/wm/preferences" = {
        action-middle-click-titlebar = "lower";
      };
      "org/gnome/system/location" = {
        enabled = true;
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
      "org/gnome/shell/extensions/dash-to-dock" = {
        apply-custom-theme = true;
        custom-theme-shrink = true;
        dash-max-icon-size = 32;
        show-mounts = false;
        click-action = "focus-or-appspread";
        scroll-action = "switch-workspace";
        intellihide-mode = "ALL_WINDOWS";
        show-dock-urgent-notify = false;
        show-trash = false;
      };
      "org/gnome/shell/extensions/gsconnect" = {
        show-indicators = true;
      };
      "org/gnome/Console" = {
        theme = "auto";
      };
      "ca/desrt/dconf-editor" = {
        show-warning = false;
      };
      "org/gnome/desktop/background" = {
        picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/field-l.svg";
        picture-uri-dark = "file:///run/current-system/sw/share/backgrounds/gnome/field-d.svg";
        primary-color = "#26a269";
        secondary-color = "#000000";
        color-shading-type = "solid";
        picture-options = "zoom";
      };
      "org/gnome/desktop/screensaver" = {
        picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/field-l.svg";
        primary-color = "#26a269";
        secondary-color = "#000000";
        color-shading-type = "solid";
        picture-options = "zoom";
      };
      "org/gnome/shell/extensions/ibus-tweaker" = {
        use-custom-font = true;
        custom-font = "sans-serif 10";
      };
      "com/raggesilver/BlackBox" = {
        terminal-padding = mkTuple [ (mkUint32 5) (mkUint32 5) (mkUint32 5) (mkUint32 5) ];
        font = "monospace 10";
        theme-light = "Tomorrow";
        theme-dark = "Tomorrow Night";
        show-menu-button = false;
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

  home.link = {
    ".config/systemd/user/gnome-session.target.wants/gnome-remote-desktop.service".target =
      "/etc/systemd/user/gnome-remote-desktop.service";
  };

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
