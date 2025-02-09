{
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  extensionPkgs = with pkgs.gnomeExtensions; [
    gsconnect
    appindicator
    dash-to-dock
    # clipboard-history
    kimpanel
    upower-battery
    alphabetical-app-grid
    customize-ibus
    caffeine
    custom-reboot
  ];
  gtkThemes = pkgs.symlinkJoin {
    name = "gtk-themes";
    paths = with pkgs; [ adw-gtk3 ];
  };
  inherit (lib.hm.gvariant)
    mkArray
    mkTuple
    mkString
    type
    ;
  longStatusBar = lib.elem "workstation" osConfig.system.types;
in
lib.mkIf osConfig.services.xserver.desktopManager.gnome.enable {
  home.packages = extensionPkgs;

  programs.chromium.extensions = [
    "gphhapmejobijbbhgpjhcjognlahblep" # GNOME Shell integration
    "jfnifeihccihocjbfcfhicmmgpjicaec" # GSConnect
  ];

  # remove initial setup dialog
  home.file.".config/gnome-initial-setup-done".text = "yes";

  # themes
  home.file.".local/share/themes".source = "${gtkThemes}/share/themes";

  dconf.settings = {
    # Do not sleep when ac power connected
    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
    };
    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = map (p: p.extensionUuid) extensionPkgs ++ [
        "light-style@gnome-shell-extensions.gcampax.github.com"
      ];
      disabled-extensions = [ ];
      favorite-apps = lib.mkBefore [
        "org.gnome.Console.desktop"
        "org.gnome.Nautilus.desktop"
        "firefox.desktop"
        "gnome-system-monitor.desktop"
        "code.desktop"
      ];
      welcome-dialog-last-shown-version = "43.1";
    };
    "org/gnome/mutter" = {
      edge-tiling = true;
      experimental-features = [
        "scale-monitor-framebuffer"
        "variable-refresh-rate"
        "xwayland-native-scaling"
      ];
    };
    "org/gnome/desktop/interface" = {
      gtk-theme = "adw-gtk3";
      clock-show-weekday = longStatusBar;
      show-battery-percentage = longStatusBar;
      locate-pointer = true;
      monospace-font-name = "Monospace 10";
    };
    "org/gnome/desktop/input-sources" = {
      sources =
        mkArray
          (type.tupleOf [
            type.string
            type.string
          ])
          [
            (mkTuple [
              (mkString "xkb")
              (mkString "us")
            ])
            (mkTuple [
              (mkString "ibus")
              (mkString "rime")
            ])
            (mkTuple [
              (mkString "ibus")
              (mkString "mozc-jp")
            ])
          ];
    };
    "org/gnome/shell/extensions/customize-ibus" = {
      use-custom-font = true;
      custom-font = "sans 11";
      input-indicator-only-on-toggle = true;
    };
    "org/gnome/shell/extensions/customreboot" = {
      use-systemd-boot = true;
      use-efibootmgr = false;
    };
    "org/gnome/shell/extensions/kimpanel" = {
      font = "Sans 11";
    };
    "org/gnome/desktop/wm/keybindings" = {
      # use fcitx5 for binding
      switch-input-source = [ ];
      switch-input-source-backward = [ ];
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
      picture-uri = "file://${pkgs.gnome-backgrounds}/share/backgrounds/gnome/symbolic-l.png";
      picture-uri-dark = "file://${pkgs.gnome-backgrounds}/share/backgrounds/gnome/symbolic-d.png";
      primary-color = "#26a269";
      secondary-color = "#000000";
      color-shading-type = "solid";
      picture-options = "zoom";
    };
    "org/gnome/desktop/screensaver" = {
      picture-uri = "file://${pkgs.gnome-backgrounds}/share/backgrounds/gnome/symbolic-l.png";
      primary-color = "#26a269";
      secondary-color = "#000000";
      color-shading-type = "solid";
      picture-options = "zoom";
    };
  };

  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };
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
    ".cache/gsconnect"
  ];
}
