{ config, lib, pkgs, ... }:

lib.mkIf config.home.graphical {
  programs = {
    mpv.enable = true;
  };

  home.packages = with pkgs; [
    anki
    bitwarden
    calibre
    element-desktop
    gimp
    gnuradio
    goldendict
    gparted
    inkscape
    keepassxc
    # TODO https://github.com/NixOS/nixpkgs/pull/187562
    #      depend to gnupg
    # libreoffice-fresh
    meld
    mplayer
    nur.repos.linyinfeng.clash-for-windows
    nur.repos.linyinfeng.icalingua-plus-plus
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
