{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [ logseq ];
  xdg.desktopEntries = {
    logseq = {
      name = "Logseq";
      exec = "logseq --enable-wayland-ime %U";
      icon = "logseq";
      settings.StartupWMClass = "Logseq";
      comment = "A privacy-first, open-source platform for knowledge management and collaboration.";
      mimeType = [ "x-scheme-handler/logseq" ];
      categories = [ "Utility" ];
    };
  };
  dconf.settings."org/gnome/shell".favorite-apps = lib.mkAfter [ "logseq.desktop" ];
  home.global-persistence.directories = [
    ".config/Logseq"
    ".logseq"
  ];
}
