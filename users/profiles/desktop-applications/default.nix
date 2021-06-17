{ pkgs, ... }:

{
  programs = {
    mpv.enable = true;

    obs-studio = {
      enable = true;
      plugins = with pkgs; [
        obs-wlrobs
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
    gnome3.dconf-editor
    gnome3.gnome-sound-recorder
    gnome3.gnome-tweaks
    gnome3.polari
    # goldendict # TODO: broken
    gparted
    inkscape
    keepass
    keepassxc
    libreoffice-fresh
    mplayer
    tdesktop
    teamspeak_client
    transmission-remote-gtk
    virt-manager
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
      ".config/unity3d/Team Cherry" # hollow knight saves
      ".config/transmission-remote-gtk"

      ".local/share/Anki2"
      ".local/share/TelegramDesktop"
      ".local/share/geary"

      "Zotero"
    ];
  };
}
