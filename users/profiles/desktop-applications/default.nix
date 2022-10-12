{ config, lib, pkgs, ... }:

lib.mkIf config.home.graphical {
  programs = {
    mpv.enable = true;
  };

  home.packages = with pkgs; [
    anki
    amberol
    bitwarden
    calibre
    element-desktop
    gimp
    gnuradio
    goldendict
    gparted
    inkscape
    keepassxc
    # libreoffice-fresh
    meld
    mplayer
    nur.repos.linyinfeng.icalingua-plus-plus
    nur.repos.linyinfeng.wemeet
    picard
    tdesktop
    teamspeak_client
    transmission-remote-gtk
    virt-manager
    vlc
    xournalpp
    zoom-us
    zotero
  ];

  home.global-persistence = {
    directories = [
      ".ts3client"
      ".zotero"
      ".goldendict"

      ".config/Bitwarden"
      ".config/calibre"
      ".config/Element"
      ".config/icalingua"
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
