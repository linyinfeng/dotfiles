{ pkgs, ... }:

{
  home.packages = with pkgs; [
    wget
    aria2
    rsync
    axel
    dnsutils
    traceroute
    iperf
    nmap-graphical
  ];
}
