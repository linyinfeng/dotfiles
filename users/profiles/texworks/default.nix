{ pkgs, ... }:

{
  home.packages = with pkgs; [
    texworks
  ];
  home.global-persistence.directories = [
    ".config/TUG"
  ];
}

