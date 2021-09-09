{ pkgs, ... }:

{
  programs = {
    mpv.enable = true;

    obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
      ];
    };

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
    gnome.dconf-editor
    gnome.gnome-sound-recorder
    gnome.gnome-tweaks
    gnome.polari
    goldendict
    gparted
    inkscape
    keepass
    keepassxc
    libreoffice-fresh
    linyinfeng.clash-for-windows
    linyinfeng.icalingua
    meld
    mplayer
    tdesktop
    teamspeak_client
    transmission-remote-gtk
    virt-manager
    vlc
    zoom-us
    zotero
  ];

  home.global-persistence = {
    directories = [
      ".ts3client"
      ".zotero"
      ".goldendict"

      ".config/calibre"
      ".config/obs-studio"
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
