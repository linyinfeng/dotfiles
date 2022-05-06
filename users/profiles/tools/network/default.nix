{ pkgs, ... }:

{
  home.packages = with pkgs; [
    wget
    aria2
    rsync
    axel
    dnsutils
    iperf
    nmap
  ];
}
