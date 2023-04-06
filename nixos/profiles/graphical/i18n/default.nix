{
  config,
  pkgs,
  lib,
  ...
}: {
  config = lib.mkMerge [
    (lib.mkIf config.services.xserver.desktopManager.gnome.enable {
      i18n.inputMethod = {
        enabled = "ibus";
        ibus.engines = with pkgs.ibus-engines; [
          (rime.override {
            rimeDataPkgs = with pkgs.nur.repos.linyinfeng.rimePackages;
              withRimeDeps [
                rime-ice
              ];
          })
          mozc
        ];
      };
    })
    (lib.mkIf config.services.xserver.desktopManager.plasma5.enable {
      i18n.inputMethod = {
        enabled = "fcitx5";
        fcitx5.addons = with pkgs; [
          (fcitx5-rime.override {
            rimeDataPkgs = with pkgs.nur.repos.linyinfeng.rimePackages;
              withRimeDeps [
                rime-ice
              ];
          })
          fcitx5-mozc
        ];
      };
    })
    {
      environment.global-persistence.user.directories = [
        ".config/mozc"
      ];
    }
  ];
}
