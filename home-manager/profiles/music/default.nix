{ pkgs, ... }:
{
  home.packages = with pkgs; [
    reaper
    lilypond
    musescore
  ];
  home.global-persistence.directories = [
    ".config/REAPER"
    ".config/MuseScore"
    ".local/share/MuseScore"
  ];
}
