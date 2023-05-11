# for peering information, please refer to https://dn42.li7g.com
# feel free to create a pull request to peer with me
{
  # trafficControl.enable = false
  # egress traffic from this server is unmetered
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
      trafficControl.enable = false;
    };
  };

  # trafficControl.enable = false
  # fsn0 has egress traffic of 20TB/month, should be enough
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
      trafficControl.enable = false;
    };
  };
}
