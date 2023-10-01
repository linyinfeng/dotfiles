{
  config,
  pkgs,
  ...
}: let
  cfg = config.programs.ccache;
in {
  programs.ccache = {
    enable = true;
    cacheDir = pkgs.ccacheCacheDir;
  };
  nix.settings.extra-sandbox-paths = [cfg.cacheDir];
  environment.global-persistence.directories = [cfg.cacheDir];
  systemd.tmpfiles.rules = [
    "z ${cfg.cacheDir} 770 root nixbld - -"
  ];
}
