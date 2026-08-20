# feel free to create a pull request to peer with my servers
# for peering information, please refer to
#
#    https://dn42.li7g.com/info.json
#
# looking glass
#
#    https://bird-lg.li7g.com
{
  mtl0 = {
    "virmach-ny1g.lantian.pub" = {
      remoteAutonomousSystem.dn42LowerNumber = 2547;
      tunnel.type = "wireguard";
      wireguard.remotePublicKey = "a+zL2tDWjwxBXd2bho2OjR/BEmRe2tJF9DHFmZIE+Rk=";
      endpoint = {
        address = "216.52.57.200";
        port = 20128;
      };
      linkAddresses = rec {
        v4.bgpNeighbor = v4.peer;
        v6.bgpNeighbor = "fe80::2547"; # link-local
        v4.peer = "172.22.76.190";
        v6.peer = "fdbc:f9dc:67ad:8::1";
      };
      bgp.community.dn42 = {
        enable = true;
        latency = 3; # rtt min/avg/max/mdev = 9.357/9.489/9.715/0.116 ms
        bandwidth = 23; # 10Mbps <= . < 100Mbps
      };
    };
    "us2.g-load.eu" = {
      remoteAutonomousSystem.dn42LowerNumber = 3914;
      tunnel.type = "wireguard";
      wireguard.remotePublicKey = "6Cylr9h1xFduAO+5nyXhFI1XJ0+Sw9jCpCDvcqErF1s=";
      endpoint = {
        address = "de2.g-load.eu";
        port = 20002;
      };
      linkAddresses = rec {
        v4.bgpNeighbor = v4.peer;
        v6.bgpNeighbor = "fe80::ade0"; # link-local
        v4.peer = "172.20.53.98";
        v6.peer = null;
      };
      bgp.community.dn42 = {
        enable = true;
        latency = 4; # rtt min/avg/max/mdev = 27.928/28.139/28.484/0.164 ms
        bandwidth = 23; # 10Mbps <= . < 100Mbps
      };
    };
  };
}
