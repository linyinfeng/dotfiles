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
    ghostscript
    github-cli
    i7z
    imagemagick
    minio-client
    p7zip
    powerstat
    powertop
    speedread
    trash-cli
    unar
    unrar
    unzip
    wl-clipboard
  ];

  home.global-persistence.directories = [
    ".config/gh" # github-cli
    ".mc" # minio-client
  ];
}
