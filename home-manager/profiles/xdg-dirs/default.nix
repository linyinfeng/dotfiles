{ config, ... }:
let
  prefix = "${config.home.homeDirectory}/Data";
in
{
  xdg.enable = true;

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    desktop = "${prefix}/Desktop";
    documents = "${prefix}/Documents";
    download = "${prefix}/Downloads";
    music = "${prefix}/Music";
    pictures = "${prefix}/Pictures";
    publicShare = "${prefix}/Public";
    templates = "${prefix}/Templates";
    videos = "${prefix}/Videos";
  };

  home.global-persistence.directories = [ "Data" ];
}
