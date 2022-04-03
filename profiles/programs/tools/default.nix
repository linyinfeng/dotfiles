{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    bandwhich
    bc
    btop
    compsize
    coreutils
    cryptsetup
    dosfstools
    dstat
    efibootmgr
    exa
    fd
    file
    git
    gptfdisk
    gptfdisk
    jq
    lm_sensors
    manix
    moreutils
    ncdu
    neofetch
    nix-index
    pciutils
    procs
    ripgrep
    rlwrap
    tmux
    usbutils
    util-linux
    yq-go
  ];
}
