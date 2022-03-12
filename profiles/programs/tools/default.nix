{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    bandwhich
    bc
    btop
    compsize
    coreutils
    cryptsetup
    curl
    dnsutils
    dosfstools
    dstat
    efibootmgr
    exa
    fd
    file
    git
    gptfdisk
    iputils
    jq
    lm_sensors
    manix
    moreutils
    ncdu
    nix-index
    procs
    ripgrep
    rlwrap
    usbutils
    util-linux
    whois
  ];
}
