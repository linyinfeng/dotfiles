{ config, pkgs, lib, ... }:

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
  };
  programs.starship.enable = true;
  programs.fzf.enable = true;
  programs.zoxide.enable = true;

  home.global-persistence = {
    directories = [
      ".local/share/zoxide"
      ".local/share/direnv"
    ];
    files = [
      ".zsh_history"
    ];
  };
}
