{
  config,
  lib,
  ...
}: let
  cfg = config.networking.dn42;
  hostName = config.networking.hostName;
  data = config.lib.self.data;
  filterHost = _name: hostData: (lib.length hostData.host_indices != 0);
  mkHost = name: hostData: {
    bgp = {
      enable = true;
      community.dn42 = regionTable.${name};
    };
    indices = hostData.host_indices;
    addressesV4 = hostData.dn42_addresses_v4;
    addressesV6 = hostData.dn42_addresses_v6;
    endpointsV4 = hostData.endpoints_v4;
    endpointsV6 = hostData.endpoints_v6;
    initiate =
      if lib.elem name ipv4OnlyHosts
      then "ipv4"
      else "ipv6";
  };
  peerTable = import ./_peers.nix;
  ipv4OnlyHosts = ["shg0"];
  trafficControlTable = {
    # Hetzner 20 TB/month
    "hil0".enable = false; # 20TB/month
    "fsn0".enable = false; # 20TB/month
    "mtl0".enable = false; # unmetered
    "mia0" = {
      # 200GB/month
      enable = true;
      rate = "5M";
    };
    "shg0" = {
      # 1TB/month
      enable = true;
      rate = "10M";
    };
    "hkg0" = {
      # 1TB/month
      enable = true;
      rate = "10M";
    };

    "nuc".enable = false; # unmetered
    "xps8930".enable = false; # mobile
    "framework".enable = false; # mobile
    "enchilada".enable = false; # mobile
  };
  regionTable = {
    "hil0" = {
      region = 44; # North America-W
      country = 1840; # United States of America
    };
    "fsn0" = {
      region = 41; # Europe
      country = 1276; # Germany
    };
    "mtl0" = {
      region = 42; # North America-E
      country = 1124; # Canada
    };
    "mia0" = {
      region = 42; # North America-E
      country = 1840; # United States of America
    };
    "shg0" = {
      region = 52; # Asia-E (JP,CN,KR,TW,HK)
      country = 1156; # China
    };
    "hkg0" = {
      region = 52; # Asia-E (JP,CN,KR,TW,HK)
      country = 1344; # Hong Kong
    };

    "nuc" = {
      region = 52; # Asia-E (JP,CN,KR,TW,HK)
      country = 1156; # China
    };
    "xps8930" = {
      region = 52; # Asia-E (JP,CN,KR,TW,HK)
      country = 1156; # China
    };
    # mobile devices
    "framework" = {
      region = null;
      country = null;
    };
    "enchilada" = {
      region = null;
      country = null;
    };
  };
in {
  networking.dn42 = {
    enable = cfg.autonomousSystem.mesh.hosts ? ${hostName};
    bgp = {
      gortr = {
        port = config.ports.gortr;
        metricPort = config.ports.gortr-metric;
      };
      collector.dn42.enable = cfg.bgp.peering.peers != {};
      peering = {
        defaults = {
          localPortStart = config.ports.dn42-peer-min;
          wireguard.localPrivateKeyFile = config.sops.secrets."wireguard_private_key".path;
          trafficControl = trafficControlTable.${hostName};
        };
        peers = peerTable.${hostName} or {};
        routingTable = {
          id = config.routingTables.peer-dn42;
          priority = config.routingPolicyPriorities.peer-dn42;
        };
      };
      routingTable = {
        id = config.routingTables.bgp-dn42;
        priority = config.routingPolicyPriorities.bgp-dn42;
      };
    };
    autonomousSystem = {
      dn42LowerNumber = 0128;
      # number = 4242420128;
      cidrV4 = data.dn42_v4_cidr;
      cidrV6 = data.dn42_v6_cidr;
      mesh = {
        hosts = lib.mapAttrs mkHost (lib.filterAttrs filterHost data.hosts);
        routingTable = {
          id = config.routingTables.mesh-dn42;
          priority = config.routingPolicyPriorities.mesh-dn42;
        };
        ipsec = {
          enable = true;
          caCert = data.ca_cert_pem;
          hostCert = data.hosts.${hostName}.ike_cert_pem;
          hostCertKeyFile = config.sops.secrets."ike_private_key_pem".path;
        };
        bird.babelInterfaceConfig = ''
          rtt cost 1024;
          rtt max 1024 ms;
        '';
        # extraInterfaces =
        #   lib.optionalAttrs config.services.zerotierone.enable {
        #     "${config.passthru.zerotierInterfaceName}" = {
        #       type = "tunnel";
        #       extraConfig = asCfg.mesh.bird.babelInterfaceConfig;
        #     };
        #   };
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
  sops.secrets."ike_private_key_pem" = {
    sopsFile = config.sops-file.terraform;
    restartUnits = ["strongswan-swanctl.service"];
  };
  networking.firewall.allowedUDPPortRanges = [
    {
      from = config.ports.dn42-peer-min;
      to = config.ports.dn42-peer-max;
    }
  ];

  # for dn42-site
  passthru.dn42TrafficControlTable = trafficControlTable;
}
