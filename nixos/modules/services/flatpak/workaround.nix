{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.flatpak.workaround;
  mkRoSymBind = path: {
    device = path;
    fsType = "fuse.bindfs";
    options = [
      "ro"
      "resolve-symlinks"
    ];
  };
  aggregatedFonts = pkgs.buildEnv {
    name = "system-fonts";
    paths = config.fonts.packages;
    pathsToLink = [ "/share/fonts" ];
  };
in
{
  options.services.flatpak.workaround = {
    font.enable = lib.mkEnableOption "flatpak font workaround";
    icon.enable = lib.mkEnableOption "flatpak icon workaround";
  };
  config = lib.mkMerge [
    (lib.mkIf (cfg.font.enable || cfg.icon.enable) { system.fsPackages = [ pkgs.bindfs ]; })
    (lib.mkIf cfg.font.enable {
      fileSystems."/usr/share/fonts" = mkRoSymBind (aggregatedFonts + "/share/fonts");
    })
    (lib.mkIf cfg.icon.enable {
      fileSystems."/usr/share/icons" = mkRoSymBind (config.system.path + "/share/icons");
    })
  ];
}
