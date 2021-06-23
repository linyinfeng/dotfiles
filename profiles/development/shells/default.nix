{ pkgs, ... }:

{
  programs.zsh.enable = true;
  programs.fish.enable = true;
  environment.systemPackages = with pkgs; [
    fishPlugins.foreign-env
  ];

  environment.global-persistence.user.directories = [
    ".local/share/fish"
  ];
}
