{ pkgs, ... }:

{
  home.packages = with pkgs; [
    android-studio
    jetbrains.idea-ultimate
    jetbrains.clion
    jetbrains.goland
  ];

  home.global-persistence.directories = [
    ".config/Google"
    ".config/JetBrains"

    ".local/share/Google"
    ".local/share/JetBrains"
  ];
}
