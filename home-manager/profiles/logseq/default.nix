{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [ logseq ];
  dconf.settings."org/gnome/shell".favorite-apps = lib.mkAfter [ "logseq.desktop" ];
  home.global-persistence.directories = [
    ".config/Logseq"
    ".logseq"
  ];
}
