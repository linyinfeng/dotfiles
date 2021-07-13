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
    bandwhich
    bc
    cntr
    compsize
    cryptsetup
    djvu2pdf
    dos2unix
    dstat
    efibootmgr
    exa
    f2fs-tools
    fd
    ffmpeg
    file
    github-cli
    gptfdisk
    hyperfine
    imagemagick
    iozone
    kmon
    lm_sensors
    loc
    ncdu
    neofetch
    p7zip
    parted
    pciutils
    pkgdiff
    procs
    rargs
    ripgrep
    rlwrap
    screenfetch
    sd
    srm
    tealdeer
    tokei
    trash-cli
    unar
    unrar
    unzip
    usbutils
    wl-clipboard
    youtube-dl
    yq-go
  ];

  home.global-persistence.directories = [
    ".config/gh"
  ];
}
