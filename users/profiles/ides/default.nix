{ pkgs, ... }:

{
  home.packages = with pkgs; [
    android-studio
    jetbrains.idea-ultimate
    jetbrains.clion
    jetbrains.goland
  ];
}
