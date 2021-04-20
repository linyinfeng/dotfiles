{ pkgs, ... }:

{
  programs.zsh.enable = true;
  programs.fish.enable = true;

  environment.global-persistence.user.directories = [
    ".local/share/fish"
  ];
}
