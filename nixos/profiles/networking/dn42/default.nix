{ config, lib, ... }:
let
  dn42Cfg = config.networking.dn42;
  meshCfg = config.networking.mesh;
  asThisHostCfg = dn42Cfg.autonomousSystem.thisHost;
  inherit (config.networking) hostName;
  dn42If = dn42Cfg.interfaces.dummy.name;
  inherit (config.lib.self) data;
  thisHostData = data.hosts.${hostName};
  inherit (config.networking.hostsData) indexedHosts;
  mkHostDn42Cfg = _name: hostData: {
    preferredAddressV4 = lib.elemAt hostData.dn42_addresses_v4 0;
    preferredAddressV6 = lib.elemAt hostData.dn42_addresses_v6 0;
  };
  peerTable = import ./_peers.nix;
  trafficControlTable = {
    # Hetzner 20 TB/month
    "fsn0".enable = false; # 20TB/month
    "mtl0".enable = false; # unmetered
    "lax0" = {
      # 2.4TB/month
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
    "parrot".enable = false; # mobile
  };
  regionTable = {
    "lax0" = {
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
    "parrot" = {
      region = null;
      country = null;
    };
  };
in
lib.mkIf meshCfg.enable {
  networking.mesh = {
    interfaces.extraPatterns = [ dn42If ];
    cidrs = {
      dn42V4 = {
        family = "ipv4";
        prefix = data.dn42_v4_cidr;
      };
      dn42V6 = {
        family = "ipv6";
        prefix = data.dn42_v6_cidr;
      };
    };
    thisHost.cidrs = {
      dn42V4.preferredAddress = asThisHostCfg.preferredAddressV4;
      dn42V6.preferredAddress = asThisHostCfg.preferredAddressV6;
    };
  };
  networking.dn42 = {
    enable = true;
    bgp = {
      gortr = {
        port = config.ports.gortr;
        metricPort = config.ports.gortr-metric;
      };
      collector.dn42.enable = dn42Cfg.bgp.peering.peers != { };
      peering = {
        defaults = {
          localPortStart = config.ports.dn42-peer-min;
          wireguard.localPrivateKeyFile = config.sops.secrets."wireguard_private_key".path;
          trafficControl = {
            inherit (trafficControlTable.${hostName}) enable rate;
          };
        };
        peers = peerTable.${hostName} or { };
      };
      routingTable = {
        id = config.routingTables.dn42-bgp;
        priority = config.routingPolicyPriorities.dn42-bgp;
      };
      community.dn42 = {
        inherit (regionTable.${hostName}) region country;
      };
    };
    autonomousSystem = {
      dn42LowerNumber = 128; # number = 4242420128;
      cidrV4 = data.dn42_v4_cidr;
      cidrV6 = data.dn42_v6_cidr;
      hosts = lib.mapAttrs mkHostDn42Cfg indexedHosts;
      thisHost = {
        addressesV4 = thisHostData.dn42_addresses_v4;
        addressesV6 = thisHostData.dn42_addresses_v6;
        preferredAddressV4 = lib.elemAt thisHostData.dn42_addresses_v4 0;
        preferredAddressV6 = lib.elemAt thisHostData.dn42_addresses_v6 0;
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
    terraformOutput = {
      enable = true;
      perHost = true;
    };
    group = "systemd-network";
    mode = "440";
    reloadUnits = [ "systemd-networkd.service" ];
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
