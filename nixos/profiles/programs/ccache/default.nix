{config, ...}: let
  cfg = config.programs.ccache;
in {
  programs.ccache.enable = true;
  nix.settings.extra-sandbox-paths = [cfg.cacheDir];
  environment.global-persistence.directories = [cfg.cacheDir];
  systemd.tmpfiles.rules = [
    "z ${cfg.cacheDir} 770 root nixbuild - -"
  ];
}
