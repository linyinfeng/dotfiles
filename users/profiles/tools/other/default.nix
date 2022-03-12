{ pkgs, ... }:

{
  programs = {
    tmux.enable = true;
    htop.enable = true;
    bat = {
      enable = true;
      config = {
        theme = "GitHub";
      };
    };
    jq.enable = true;
  };

  home.packages = with pkgs; [
    ffmpeg
    github-cli
    imagemagick
    p7zip
    speedread
    trash-cli
    unar
    unrar
    unzip
    wl-clipboard
  ];

  home.global-persistence.directories = [
    ".config/gh"
  ];
}
