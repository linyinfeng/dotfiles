{ pkgs, ... }:

{
  programs = {
    chromium.enable = true;
    firefox.enable = true;

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
    goldendict
    gparted
    inkscape
    keepass
    keepassxc
    libreoffice-fresh
    mplayer
    tdesktop
    teamspeak_client
    virt-manager
    zoom-us
    zotero
  ];
}
