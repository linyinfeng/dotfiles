{
  config,
  pkgs,
  ...
}: {
  programs = {
    traceroute.enable = true;
    mtr.enable = true;
    wireshark.enable = true;
  };
  environment.systemPackages = with pkgs; [
    curl
    dnsutils
    inetutils
    iperf
    iputils
    nftables
    tcpdump
    ipcalc
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
