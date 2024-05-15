{ config, pkgs, ... }:
let
  optionalPkg = config.lib.self.optionalPkg pkgs;
in
{
  home.packages =
    with pkgs;
    [
      amberol
      calibre
      element-desktop
      fractal
      gimp
      gnuradio
      gparted
      inkscape
      libreoffice-fresh
      meld
      mission-center
      picard
      praat
      qq
      tdesktop
      teamspeak_client
      transmission-remote-gtk
      virt-manager
      vlc
      xournalpp
      zotero
    ]
    ++ optionalPkg [
      "nur"
      "repos"
      "linyinfeng"
      "wemeet"
    ];

  dconf.settings = {
    "org/gnome/shell" = {
      favorite-apps = [ "zotero.desktop" ];
    };
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [
        "qemu:///system"
        "qemu+ssh://root@nuc/system"
      ];
    };
    "io/missioncenter/MissionCenter" = {
      performance-page-cpu-graph = "2";
    };
  };

  home.global-persistence = {
    directories = [
      ".ts3client"
      ".zotero"
      ".goldendict"

      ".config/calibre"
      ".config/Element"
      # ".config/SchildiChat"
      ".config/icalingua"
      ".config/QQ"
      ".config/unity3d" # unity3d game saves
      ".config/transmission-remote-gtk"
      ".config/MusicBrainz" # picard configs
      ".config/inkscape"

      ".local/share/Anki2"
      ".local/share/TelegramDesktop"
      ".local/share/geary"
      ".local/share/fractal"

      "Zotero"
    ];
  };
}
