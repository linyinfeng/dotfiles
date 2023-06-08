{
  config,
  pkgs,
  ...
}: {
  programs = {
    bandwhich.enable = true;
    traceroute.enable = true;
    mtr.enable = true;
    wireshark.enable = true;
  };
  environment.systemPackages = with pkgs; [
    curl
    dnsutils
    ethtool
    inetutils
    ipcalc
    iperf
    iputils
    nftables
    nmap
    tcpdump
  ];
  networking.firewall = {
    allowedTCPPorts = [
      config.ports.iperf
    ];
    allowedUDPPorts = [
      config.ports.iperf
    ];
  };
}
