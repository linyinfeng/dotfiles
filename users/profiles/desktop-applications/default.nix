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
    calibre
    element-desktop
    gimp
    goldendict
    gparted
    inkscape
    keepassxc
    # TODO libreoffice-fresh broken
    # https://github.com/NixOS/nixpkgs/issues/153436
    # libreoffice-fresh
    libreoffice
    meld
    mplayer
    nur.repos.linyinfeng.clash-for-windows
    nur.repos.linyinfeng.icalingua
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

      ".config/calibre"
      ".config/Element"
      ".config/unity3d" # unity3d game saves
      ".config/transmission-remote-gtk"
      ".config/icalingua"

      ".local/share/Anki2"
      ".local/share/TelegramDesktop"
      ".local/share/geary"

      "Zotero"
    ];
  };
}
