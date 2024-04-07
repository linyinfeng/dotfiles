{ pkgs, ... }:
{
  # manage bat config
  programs.bat = {
    enable = true;
    config = {
      theme = "GitHub";
    };
  };

  home.packages = with pkgs; [
    ffmpeg
    ghostscript
    imagemagick
    minio-client
    nur.repos.linyinfeng.mstickereditor
    wl-clipboard
    xdg-ninja
  ];

  home.global-persistence.directories = [
    ".mc" # minio-client
    ".config/mstickereditor"
  ];
}
