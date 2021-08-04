{ pkgs, ... }:

{
  programs.zsh.enable = true;
  programs.fish.enable = true;
  environment.systemPackages = with pkgs; [
    fishPlugins.foreign-env
  ];

  programs.tprofile.enable = true;

  environment.global-persistence.user.directories = [
    ".local/share/fish"
  ];
}
