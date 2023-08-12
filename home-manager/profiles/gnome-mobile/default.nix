{
  pkgs,
  lib,
  osConfig,
  ...
}: let
  extensionPkgs = with pkgs.gnomeExtensions; [
    gsconnect
    customize-ibus
    caffeine
  ];
  inherit (lib.hm.gvariant) mkArray mkTuple mkString type;
in
  lib.mkIf osConfig.services.xserver.desktopManager.gnome.enable
  {
    home.packages = extensionPkgs;

    dconf.settings = {
      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = map (p: p.extensionUuid) extensionPkgs;
        disabled-extensions = [];
      };
      "org/gnome/desktop/input-sources" = {
        sources = mkArray (type.tupleOf [type.string type.string]) [
          (mkTuple [(mkString "xkb") (mkString "us")])
          (mkTuple [(mkString "ibus") (mkString "rime")])
          (mkTuple [(mkString "ibus") (mkString "mozc-jp")])
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
        picture-uri = "file://${pkgs.gnome.gnome-backgrounds}/share/backgrounds/gnome/symbolic-d.webp";
        picture-uri-dark = "file://${pkgs.gnome.gnome-backgrounds}/share/backgrounds/gnome/symbolic-d.webp";
        primary-color = "#26a269";
        secondary-color = "#000000";
        color-shading-type = "solid";
        picture-options = "zoom";
      };
      "org/gnome/desktop/screensaver" = {
        picture-uri = "file://${pkgs.gnome.gnome-backgrounds}/share/backgrounds/gnome/symbolic-d.webp";
        primary-color = "#26a269";
        secondary-color = "#000000";
        color-shading-type = "solid";
        picture-options = "zoom";
      };
    };

    home.activation.allowGdmReadFace = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${pkgs.acl}/bin/setfacl --modify=group:gdm:--x "$HOME"
    '';

    home.global-persistence.directories = [
      ".config/gsconnect"
    ];
  }
