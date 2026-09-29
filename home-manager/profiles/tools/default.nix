{ lib, pkgs, ... }:
{
  # manage bat config
  programs.bat = {
    enable = true;
    config = {
      theme = "ansi";
    };
  };
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
  };

  home.packages =
    with pkgs;
    [
      # keep-sorted start
      fd
      ffmpeg
      ghostscript
      imagemagick
      linyinfeng.mstickereditor
      minio-client
      nixfmt
      ripgrep
      # keep-sorted end
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      wl-clipboard
      xdg-ninja
    ];

  home.global-persistence.directories = [
    ".mc" # minio-client
    ".config/mstickereditor"
  ];
}
