{ pkgs, ... }:
{
  programs = {
    bandwhich.enable = true;
    traceroute.enable = true;
    mtr.enable = true;
    trippy.enable = true;
    wireshark.enable = true;
  };
  environment.systemPackages = with pkgs; [
    # keep-sorted start
    aria2
    axel
    curl
    dnsutils
    ethtool
    inetutils
    ipcalc
    iputils
    nftables
    nmap
    rsync
    tcpdump
    wget
    # keep-sorted end
  ];
}
