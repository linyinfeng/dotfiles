{ lib, pkgs, ... }:
lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  home.packages = with pkgs; [
    texworks
    texstudio
  ];
  home.global-persistence.directories = [
    ".config/TUG"
    ".config/texstudio"
  ];
}
