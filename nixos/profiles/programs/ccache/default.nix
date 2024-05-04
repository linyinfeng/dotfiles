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
  systemd.tmpfiles.settings."50-ccache" = {
    ${cfg.cacheDir} = {
      d = {
        user = "root";
        group = "nixbld";
        mode = "0770";
      };
    };
    ${pkgs.ccacheLogDir} = {
      d = {
        user = "root";
        group = "nixbld";
        mode = "0750";
      };
    };
    "${pkgs.ccacheLogDir}/ccache.log" = {
      f = {
        user = "root";
        group = "nixbld";
        mode = "660";
      };
    };
  };
  services.logrotate.settings = {
    "${pkgs.ccacheLogDir}/ccache.log" = {
      create = "0660 root nixbld";
      size = "10M";
      compress = true;
      rotate = 1;
    };
  };
}
