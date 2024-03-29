{ pkgs, lib, ... }:
{
  i18n.inputMethod = {
    enabled = lib.mkDefault "fcitx5";
    ibus.engines = with pkgs.ibus-engines; [
      (rime.override {
        rimeDataPkgs = with pkgs.nur.repos.linyinfeng.rimePackages; withRimeDeps [ rime-ice ];
      })
      mozc
    ];
    fcitx5.addons = with pkgs; [
      (fcitx5-rime.override {
        rimeDataPkgs = with pkgs.nur.repos.linyinfeng.rimePackages; withRimeDeps [ rime-ice ];
      })
      fcitx5-mozc
    ];
  };
  environment.global-persistence.user.directories = [
    ".config/ibus"
    ".config/fcitx5"
    ".config/mozc"
  ];
}
