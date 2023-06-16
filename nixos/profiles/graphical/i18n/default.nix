{pkgs, ...}: {
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
    # not using
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
  environment.global-persistence.user.directories = [
    ".config/fcitx5"
    ".config/mozc"
  ];
}
