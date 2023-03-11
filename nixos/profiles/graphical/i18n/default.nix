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
      i18n.inputMethod.rime = {
        enableDefaultRimeData = false;
        packages = with pkgs.nur.repos.linyinfeng.rimePackages;
          withRimeDeps [
            rime-ice
          ];
      };
      environment.global-persistence.user.directories = [
        ".config/mozc"
      ];
    }
  ];
}
