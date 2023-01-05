{ config, lib, pkgs, ... }:

lib.mkIf config.home.graphical {
  home.packages = with pkgs; [
    amberol
    bitwarden
    calibre
    element-desktop
    gimp
    gnuradio
    gparted
    inkscape
    libreoffice-fresh
    meld
    nur.repos.linyinfeng.icalingua-plus-plus
    nur.repos.linyinfeng.wemeet
    picard
    qq
    tdesktop
    teamspeak_client
    transmission-remote-gtk
    virt-manager
    vlc
    xournalpp
    zoom-us
    zotero
  ];

  dconf.settings = {
    "org/gnome/shell" = {
      favorite-apps = [
        "zotero-${pkgs.zotero.version}.desktop"
      ];
    };
    "org/virt-manager/virt-manager/connections" = {
      uris = [ "qemu+ssh://root@nuc.ts.li7g.com/system" ];
    };
  };

  home.global-persistence = {
    directories = [
      ".ts3client"
      ".zotero"
      ".goldendict"

      ".config/Bitwarden"
      ".config/calibre"
      ".config/Element"
      ".config/icalingua"
      ".config/QQ"
      ".config/unity3d" # unity3d game saves
      ".config/transmission-remote-gtk"
      ".config/MusicBrainz" # picard configs

      ".local/share/Anki2"
      ".local/share/TelegramDesktop"
      ".local/share/geary"
      ".local/share/minecraft.nix"

      "Zotero"
    ];
  };
}
