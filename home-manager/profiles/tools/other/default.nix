{pkgs, ...}: {
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
    i7z
    imagemagick
    minio-client
    nur.repos.linyinfeng.mstickereditor
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
    ".mc" # minio-client
    ".config/mstickereditor"
  ];
}
