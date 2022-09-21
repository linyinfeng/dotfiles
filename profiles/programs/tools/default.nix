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
    jq
    lm_sensors
    manix
    moreutils
    ncdu
    parted
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
