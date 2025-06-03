{
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  extensionPkgs = with pkgs.gnomeExtensions; [
    gsconnect
    customize-ibus
    caffeine
    alphabetical-app-grid
  ];
  inherit (lib.hm.gvariant)
    mkArray
    mkTuple
    mkString
    type
    ;
in
lib.mkIf osConfig.services.desktopManager.gnome.enable {
  home.packages = extensionPkgs;

  dconf.settings = {
    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-battery-type = "nothing";
    };
    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = map (p: p.extensionUuid) extensionPkgs;
      disabled-extensions = [ ];
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
      custom-font = "sans-serif 10";
      input-indicator-only-on-toggle = true;
    };
    "org/gnome/system/location" = {
      enabled = true;
    };
    "org/gnome/Console" = {
      theme = "auto";
    };
    "ca/desrt/dconf-editor" = {
      show-warning = false;
    };
    "org/gnome/desktop/background" = {
      picture-uri = "file://${pkgs.gnome-backgrounds}/share/backgrounds/gnome/symbolic-d.png";
      picture-uri-dark = "file://${pkgs.gnome-backgrounds}/share/backgrounds/gnome/symbolic-d.png";
      primary-color = "#26a269";
      secondary-color = "#000000";
      color-shading-type = "solid";
      picture-options = "zoom";
    };
    "org/gnome/desktop/screensaver" = {
      picture-uri = "file://${pkgs.gnome-backgrounds}/share/backgrounds/gnome/symbolic-d.png";
      primary-color = "#26a269";
      secondary-color = "#000000";
      color-shading-type = "solid";
      picture-options = "zoom";
    };
  };

  home.activation.allowGdmReadFace = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.acl}/bin/setfacl --modify=group:gdm:--x "$HOME"
  '';

  home.global-persistence.directories = [
    ".config/gsconnect"
    ".cache/gsconnect"
  ];
}
