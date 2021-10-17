{ config, pkgs, lib, ... }:

lib.mkMerge [
  (lib.mkIf config.services.xserver.desktopManager.gnome.enable {
    i18n.inputMethod = {
      enabled = "ibus";
      ibus.engines = [
        pkgs.ibus-engines.rime
      ];
    };
  })
  (lib.mkIf config.services.xserver.desktopManager.plasma5.enable {
    i18n.inputMethod = {
      enabled = "fcitx5";
      fcitx5.addons = [
        pkgs.fcitx5-rime
      ];
    };
  })
]

