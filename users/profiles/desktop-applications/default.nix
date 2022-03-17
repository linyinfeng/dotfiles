{ config, lib, pkgs, ... }:

lib.mkIf config.home.graphical {
  programs = {
    mpv.enable = true;

    zathura = {
      enable = true;
      extraConfig = ''
        map <C-n> scroll down
        map <C-p> scroll up
        map <C-v> scroll full-down
        map <A-v> scroll full-up
      '';
      options = {
        adjust-open = "width";
      };
    };
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
    libreoffice-fresh
    lollypop
    meld
    mplayer
    nur.repos.linyinfeng.clash-for-windows
    nur.repos.linyinfeng.icalingua-plus-plus
    picard
    tdesktop
    teamspeak_client
    tigervnc
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

      "Zotero"
    ];
  };
}
