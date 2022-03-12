{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    coreutils
    curl
    dnsutils
    dosfstools
    fd
    git
    gptfdisk
    iputils
    jq
    manix
    moreutils
    nix-index
    ripgrep
    usbutils
    util-linux
    whois
  ];
}
