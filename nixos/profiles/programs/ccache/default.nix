{config, ...}: let
  cfg = config.programs.ccache;
in {
  programs.ccache.enable = true;
  nix.settings.extra-sandbox-paths = [cfg.cacheDir];
  environment.global-persistence.directories = [cfg.cacheDir];
}
