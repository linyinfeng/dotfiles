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
    cntr
    djvu2pdf
    dos2unix
    f2fs-tools
    ffmpeg
    github-cli
    gptfdisk
    hyperfine
    i7z
    imagemagick
    iozone
    kmon
    loc
    neofetch
    p7zip
    parted
    pciutils
    pkgdiff
    rargs
    screenfetch
    sd
    speedread
    srm
    tealdeer
    tokei
    trash-cli
    unar
    unrar
    unzip
    wl-clipboard
    youtube-dl
    yq-go
  ];

  home.global-persistence.directories = [
    ".config/gh"
  ];
}
