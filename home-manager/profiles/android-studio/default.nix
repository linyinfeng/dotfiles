{ pkgs, ... }:
{
  home.packages = with pkgs; [
    android-studio
  ];

  home.global-persistence.directories = [
    ".config/Google"
    ".config/.android"
    "Android"
  ];
}
