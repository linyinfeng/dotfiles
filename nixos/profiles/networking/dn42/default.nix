{
  config,
  lib,
  ...
}: let
  hostName = config.networking.hostName;
  data = config.lib.self.data;
  mkHost = name: hostData: {
    bgp.enable = true;
    indices = hostData.dn42_host_indices;
    addressesV4 = hostData.dn42_v4_addresses;
    addressesV6 = hostData.dn42_v6_addresses;
    endpointsV4 = hostData.endpoints_v4;
    endpointsV6 = hostData.endpoints_v6;
  };
  peerTable = {
    # peering guide to AS4242420128
    # for endpoints and address information, please refer to the data file (lib/data/data.json)
    # for every host "HOST" in my ASN:
    # avaiable tunnel type: currently wireguard only
    #   wireguard:
    #     ipv4 endpoint of HOST: data.hosts.${HOST}.endpoints_v4
    #     ipv6 endpoint of HOST: data.hosts.${HOST}.endpoints_v6
    #       (hosts without any endpoints is not availiable for peering)
    #     port: last 5 digits of your dn42 ASN
    #     public key of HOST: data.hosts.${HOST}
    # tunnel network information
    #   ipv6 link local: fe80::128
    #   ipv6 dn42: data.hosts.${HOST}.dn42_v6_addresses
    #   ipv4 dn42: data.hosts.${HOST}.dn42_v4_addresses
    rica = {
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
        # egress from this server is unmetered
        trafficControl.enable = false;
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
        # 20TB/month should be enough
        trafficControl.enable = false;
      };
    };
  };
in {
  networking.dn42 = {
    enable = true;
    bgp = {
      gortr = {
        port = config.ports.gortr;
        metricPort = config.ports.gortr-metric;
      };
      peering = {
        defaults = {
          localPortStart = config.ports.dn42-peer-min;
          wireguard.localPrivateKeyFile = config.sops.secrets."wireguard_private_key".path;
        };
        peers = peerTable.${hostName} or {};
      };
    };
    autonomousSystem = {
      dn42LowerNumber = 0128;
      # number = 4242420128;
      cidrV4 = data.dn42_v4_cidr;
      cidrV6 = data.dn42_v6_cidr;
      mesh = {
        hosts = lib.mapAttrs mkHost data.hosts;
      };
    };
    dns.enable = true;
    certificateAuthority.trust = true;
  };

  # bird-lg proxy
  services.bird-lg.proxy = {
    enable = true;
    listenAddress = "[::]:${toString config.ports.bird-lg-proxy}";
  };
  # tailscale as control plane
  networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [
    config.ports.bird-lg-proxy
  ];

  # wireguard
  sops.secrets."wireguard_private_key" = {
    sopsFile = config.sops-file.terraform;
    group = "systemd-network";
    mode = "440";
    restartUnits = ["systemd-networkd.service"];
  };
  networking.firewall.allowedUDPPortRanges = [
    {
      from = config.ports.dn42-peer-min;
      to = config.ports.dn42-peer-max;
    }
  ];
}
