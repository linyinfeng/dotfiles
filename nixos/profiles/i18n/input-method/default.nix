{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.i18n.inputMethod;
in
{
  options = {
    i18n.inputMethod.rime.rimeDataPkgs = lib.mkOption {
      type = with lib.types; listOf package;
      default = with pkgs; [ rime-data ];
      apply = pkgs.linyinfeng.rimePackages.withRimeDeps;
    };
  };
  config = {
    i18n.inputMethod = {
      enable = true;
      type = lib.mkDefault "fcitx5";
      ibus.engines = with pkgs.ibus-engines; [
        (rime.override { inherit (cfg.rime) rimeDataPkgs; })
        mozc
      ];
      fcitx5.addons = with pkgs; [
        (fcitx5-rime.override { inherit (cfg.rime) rimeDataPkgs; })
        fcitx5-mozc
      ];
      rime.rimeDataPkgs = with pkgs.linyinfeng.rimePackages; [ rime-ice ];
    };
    environment.global-persistence.user.directories = [
      ".config/ibus"
      ".config/fcitx5"
      ".config/mozc"
    ];
  };
}
