{ config, pkgs, lib, ... }:

lib.mkMerge [
  (lib.mkIf config.services.xserver.desktopManager.gnome.enable {
    i18n.inputMethod = {
      enabled = "ibus";
      ibus.engines = with pkgs.ibus-engines; [
        rime
        mozc
      ];
    };
  })
  (lib.mkIf config.services.xserver.desktopManager.plasma5.enable {
    i18n.inputMethod = {
      enabled = "fcitx5";
      fcitx5.addons = with pkgs; [
        fcitx5-rime
        fcitx5-mozc
      ];
    };
  })
  {
    i18n.inputMethod.rime.packages = [
      pkgs.nur.repos.linyinfeng.rime-ice
    ];
    environment.global-persistence.user.directories = [
      ".config/mozc"
    ];
  }
]
