{ config, pkgs, ... }:
let
  cfg = config.programs.ccache;
in
{
  programs.ccache = {
    enable = true;
    cacheDir = pkgs.ccacheCacheDir;
  };
  nix.settings.extra-sandbox-paths = [
    cfg.cacheDir
    pkgs.ccacheLogDir
  ];
  environment.global-persistence.directories = [ cfg.cacheDir ];
  systemd.tmpfiles.rules = [
    "d ${cfg.cacheDir}                 770 root nixbld - -"
    "d ${pkgs.ccacheLogDir}            750 root nixbld - -"
    "f ${pkgs.ccacheLogDir}/ccache.log 660 root nixbld - -"
  ];
  services.logrotate.settings = {
    "${pkgs.ccacheLogDir}/ccache.log" = {
      create = "0660 root nixbld";
      size = "10M";
      compress = true;
      rotate = 1;
    };
  };
}
