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
    addressesV4 = hostData.dn42_addresses_v4;
    addressesV6 = hostData.dn42_addresses_v6;
    endpointsV4 = hostData.endpoints_v4;
    endpointsV6 = hostData.endpoints_v6;
  };
  peerTable = import ./_peers.nix;
  trafficControlTable = {
    # Hetzner 20 TB/month
    "hil0".enable = false; # 20TB/month
    "fsn0".enable = false; # 20TB/month
    "mtl0".enable = false; # unmetered
    "mia0".enable = true; # 200GB/month
    "shg0".enable = true; # 1TB/month

    "nuc".enable = false; # unmetered
    "xps8930".enable = false; # mobile
    "framework".enable = false; # mobile
  };
  cfg = config.networking.dn42;
  asCfg = cfg.autonomousSystem;
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
          trafficControl = trafficControlTable.${hostName};
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
        extraInterfaces =
          lib.optionalAttrs config.services.zerotierone.enable {
            "${config.passthru.zerotierInterfaceName}" = {
              type = "tunnel";
              extraConfig = asCfg.mesh.bird.babelInterfaceConfig;
            };
          }
          // lib.optionalAttrs config.services.tailscale.enable {
            "${config.services.tailscale.interfaceName}" = {
              type = "tunnel";
              extraConfig = asCfg.mesh.bird.babelInterfaceConfig;
            };
          };
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
