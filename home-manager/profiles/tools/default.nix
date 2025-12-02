{ pkgs, ... }:
{
  # manage bat config
  programs.bat = {
    enable = true;
    config = {
      theme = "ansi";
    };
  };

  home.packages = with pkgs; [
    # keep-sorted start
    ffmpeg
    ghostscript
    imagemagick
    linyinfeng.mstickereditor
    minio-client
    wl-clipboard
    xdg-ninja
    # keep-sorted end
  ];

  home.global-persistence.directories = [
    ".mc" # minio-client
    ".config/mstickereditor"
  ];
}
