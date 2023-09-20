{
  config,
  pkgs,
  ...
}: let
  optionalPkg = config.lib.self.optionalPkg pkgs;
in {
  home.packages = with pkgs;
    [
      amberol
      calibre
      gimp
      gnuradio
      gparted
      inkscape
      libreoffice-fresh
      meld
      picard
      praat
      qq
      schildichat-desktop
      tdesktop
      teamspeak_client
      transmission-remote-gtk
      virt-manager
      vlc
      xournalpp
      zotero
    ]
    ++ optionalPkg ["nur" "repos" "linyinfeng" "wemeet"];

  dconf.settings = {
    "org/gnome/shell" = {
      favorite-apps = [
        "zotero-${pkgs.zotero.version}.desktop"
      ];
    };
    "org/virt-manager/virt-manager/connections" = {
      uris = ["qemu+ssh://root@nuc.ts.li7g.com/system"];
    };
  };

  home.global-persistence = {
    directories = [
      ".ts3client"
      ".zotero"
      ".goldendict"

      ".config/calibre"
      ".config/SchildiChat"
      ".config/icalingua"
      ".config/QQ"
      ".config/unity3d" # unity3d game saves
      ".config/transmission-remote-gtk"
      ".config/MusicBrainz" # picard configs
      ".config/inkscape"

      ".local/share/Anki2"
      ".local/share/TelegramDesktop"
      ".local/share/geary"

      "Zotero"
    ];
  };
}
