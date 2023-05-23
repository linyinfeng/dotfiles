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
  };
  fsn0 = {
    "de2.g-load.eu" = {
      remoteAutonomousSystem.dn42LowerNumber = 3914;
      tunnel.type = "wireguard";
      wireguard.remotePublicKey = "B1xSG/XTJRLd+GrWDsB06BqnIq8Xud93YVh/LYYYtUY=";
      endpoint = {
        address = "de2.g-load.eu";
        port = 20128;
      };
      linkAddresses = rec {
        v4.bgpNeighbor = v4.peer;
        v6.bgpNeighbor = "fe80::ade0"; # link-local
        v4.peer = "172.20.53.97";
        v6.peer = "fdfc:e23f:fb45:3234::1";
      };
      bgp.community.dn42 = {
        enable = true;
        latency = 2; # rtt min/avg/max/mdev = 3.207/3.743/4.949/0.493 ms
        bandwidth = 24; # 100Mbps <= . < 1000Mbps
      };
    };
  };
  hkg0 = {
    "hk.kskb.eu.org" = {
      remoteAutonomousSystem.dn42LowerNumber = 1817;
      tunnel.type = "wireguard";
      wireguard.remotePublicKey = "olXrGZKg3kKPdihHNfZ3zwwt+LPFQv9GMxLyA92fQl0=";
      endpoint = {
        address = "hk.kskb.eu.org";
        port = 20128;
      };
      linkAddresses = {
        v4.bgpNeighbor = null; # MP-BGP
        v6.bgpNeighbor = "fe80::1817"; # link-local
        v4.peer = "172.22.77.47";
        v6.peer = "fd28:cb8f:4c92:7777::7";
      };
      bgp.community.dn42 = {
        enable = true;
        # ipv4: rtt min/avg/max/mdev = 1.834/1.931/2.184/0.094 ms
        # ipv6: rtt min/avg/max/mdev = 2.391/2.519/2.661/0.074 ms
        latency = 1;
        bandwidth = 22; # 1Mbps <= . < 10Mbps
      };
    };
  };
}
