{ config, pkgs, ... }:
{
  programs = {
    bandwhich.enable = true;
    traceroute.enable = true;
    mtr.enable = true;
    wireshark.enable = true;
  };
  environment.systemPackages = with pkgs; [
    # sorted list for convenience
    curl
    dnsutils
    ethtool
    inetutils
    ipcalc
    iputils
    nftables
    nmap
    tcpdump
    wget
    aria2
    rsync
    axel
  ];
}
