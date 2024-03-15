{ config, pkgs, ... }:
let
  optionalPkg = config.lib.self.optionalPkg pkgs;
in
{
  programs = {
    tmux.enable = true;
    bat = {
      enable = true;
      config = {
        theme = "GitHub";
      };
    };
    jq.enable = true;
  };

  home.packages =
    with pkgs;
    [
      ffmpeg
      ghostscript
      imagemagick
      libtree
      minio-client
      nur.repos.linyinfeng.mstickereditor
      p7zip
      powerstat
      powertop
      trash-cli
      unar
      unrar
      unzip
      wl-clipboard
      xdg-ninja
    ]
    ++ optionalPkg [ "i7z" ];

  home.global-persistence.directories = [
    ".mc" # minio-client
    ".config/mstickereditor"
  ];
}
