{
  config,
  pkgs,
  lib,
  ...
}:
let
  optionalPkg = config.lib.self.optionalPkg pkgs;
in
{
  home.packages =
    with pkgs;
    [
      # keep-sorted start
      amberol
      calibre
      clapper
      element-desktop
      gimp
      # gnuradio # unused
      gparted
      inkscape
      libreoffice-fresh
      meld
      mission-center
      picard
      praat
      qq
      tdesktop
      transmission-remote-gtk
      virt-manager
      virt-viewer
      xournalpp
      zeal
      zotero
      # keep-sorted end
    ]
    ++ optionalPkg [
      "nur"
      "repos"
      "linyinfeng"
      "wemeet"
    ];

  xdg.desktopEntries = {
    qq = {
      name = "QQ";
      exec = "qq --enable-wayland-ime %U";
      icon = "qq";
      categories = [ "Network" ];
      settings.StartupWMClass = "QQ";
    };
    element-desktop = {
      name = "Element";
      genericName = "Matrix Client";
      exec = "element-desktop --enable-wayland-ime %U";
      icon = "element";
      mimeType = [ "x-scheme-handler/element" ];
      categories = [
        "Network"
        "InstantMessaging"
        "Chat"
      ];
      comment = "A feature-rich client for Matrix.org";
      settings.StartupWMClass = "Element";
    };
  };

  dconf.settings = {
    "org/gnome/shell" = {
      favorite-apps = [
        "zotero.desktop"
        "io.missioncenter.MissionCenter.desktop"
      ];
    };
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [
        "qemu:///system"
        "qemu+ssh://root@nuc/system"
      ];
    };
    "io/missioncenter/MissionCenter" = {
      performance-page-cpu-graph = 2;
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
      ".local/share/Zeal"

      "Zotero"
    ];
  };
}
