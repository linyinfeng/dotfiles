{
  config,
  lib,
  ...
}: let
  cfg = config.networking.dn42;
  data = config.lib.self.data;
  mkHost = name: hostData: {
    indices = hostData.dn42_host_indices;
    addressesV4 = hostData.dn42_v4_addresses;
    addressesV6 = hostData.dn42_v6_addresses;
    endpointsV4 = hostData.endpoints_v4;
    endpointsV6 = hostData.endpoints_v6;
  };
in {
  networking.dn42 = {
    enable = true;
    bgp = {
      enable = with cfg.autonomousSystem.mesh.thisHost; endpointsV4 ++ endpointsV6 != [];
      gortr = {
        port = config.ports.gortr;
        metricPort = config.ports.gortr-metric;
      };
      peering = {
        defaults = {
          localPortStart = config.ports.dn42-peer-min;
          wireguard.localPrivateKeyFile = config.sops.secrets."wireguard_private_key".path;
        };
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
  };

  # wireguard
  sops.secrets."wireguard_private_key" = {
    sopsFile = config.sops-file.terraform;
    group = "systemd-network";
    restartUnits = ["systemd-networkd.service"];
  };
  networking.firewall.allowedUDPPortRanges = [
    {
      from = config.ports.dn42-peer-min;
      to = config.ports.dn42-peer-max;
    }
  ];
}
