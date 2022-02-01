{ config, pkgs, lib, ... }:

let
  cfg = config.home.global-persistence;
  sysCfg = config.passthrough.systemConfig.environment.global-persistence;
in
{
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [
        "history-substring-search"
      ];
    };
    initExtra = ''
      bindkey -M emacs '^P' history-substring-search-up
      bindkey -M emacs '^N' history-substring-search-down
    '';
    history = lib.mkIf (config.home.global-persistence.enabled) {
      path = "../../${sysCfg.root}${cfg.home}/.zsh_history";
    };
  };
  programs.fish.enable = true;
  programs.skim.enable = true;
  programs.zoxide.enable = true;

  home.global-persistence.directories = [
    ".local/share/zoxide"
    ".local/share/direnv"
  ];
}
