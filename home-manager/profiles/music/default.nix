{ pkgs, lib, ... }:
let
  inherit (pkgs) ardour;
  ardourMajorVersion = lib.versions.major ardour.version;
in
{
  home.packages = with pkgs; [
    ardour
    musescore
  ];
  home.global-persistence.directories = [
    ".config/ardour${toString ardourMajorVersion}"
    ".config/MuseScore"
    ".local/share/MuseScore"
  ];
}
