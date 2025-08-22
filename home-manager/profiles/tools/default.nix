{ pkgs, ... }:
{
  programs.bat.enable = true;
  programs.btop.enable = true;

  home.packages = with pkgs; [
    # keep-sorted start
    ffmpeg
    ghostscript
    imagemagick
    minio-client
    nur.repos.linyinfeng.mstickereditor
    wl-clipboard
    xdg-ninja
    # keep-sorted end
  ];

  home.global-persistence.directories = [
    ".mc" # minio-client
    ".config/mstickereditor"
  ];
}
