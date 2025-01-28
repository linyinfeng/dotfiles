{ pkgs, ... }:
{
  home.packages = with pkgs; [
    reaper
    musescore
  ];
  home.global-persistence.directories = [
    ".config/REAPER"
    ".config/MuseScore"
    ".local/share/MuseScore"
  ];
}
