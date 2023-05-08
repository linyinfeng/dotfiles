{
  config,
  lib,
  ...
}: let
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
      enable = true;
      gortr = {
        port = config.ports.gortr;
        metricPort = config.ports.gortr-metric;
      };
    };
    autonomousSystem = {
      number = 4242420128;
      cidrV4 = data.dn42_v4_cidr;
      cidrV6 = data.dn42_v6_cidr;
      mesh = {
        hosts = lib.mapAttrs mkHost data.hosts;
      };
    };
  };
}
