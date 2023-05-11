{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.networking.dn42;
  bgpCfg = cfg.bgp;
  asCfg = cfg.autonomousSystem;

  json = pkgs.formats.json {};
  data = config.lib.self.data;
  filterHost = name: hostCfg: (hostCfg.endpointsV4 ++ hostCfg.endpointsV6) != [];
  mkHostInfo = name: hostCfg: {
    dn42 = {
      addresses = {
        v4 = hostCfg.addressesV4;
        v6 = hostCfg.addressesV6;
      };
    };
    tunnel = {
      supported_types = config.passthru.dn42.supportedTunnelTypes;
      network = {
        addresses = {
          v4 = hostCfg.addressesV4;
          v6 = config.networking.dn42.bgp.peering.defaults.linkAddresses.v6.local ++ hostCfg.addressesV6;
        };
      };
      wireguard = {
        endpoints = {
          v4 = hostCfg.endpointsV4;
          v6 = hostCfg.endpointsV6;
        };
        public_key = data.hosts.${name}.wireguard_public_key;
        port = "Last 5 digits of your ASN";
      };
    };
  };
  info = {
    autonomous_system = {
      number = asCfg.number;
      cidrs = {
        v4 = asCfg.cidrV4;
        v6 = asCfg.cidrV6;
      };
    };
    hosts = lib.mapAttrs mkHostInfo (lib.filterAttrs filterHost asCfg.mesh.hosts);
  };
  siteRoot = pkgs.runCommandNoCC "dn42-site-root" {} ''
    mkdir -p $out
    cp "${json.generate "info.json" info}" $out/info.json
  '';
in {
  services.nginx.virtualHosts."dn42.*" = {
    forceSSL = true;
    useACMEHost = "main";
    locations."/" = {
      index = "info.json";
      root = siteRoot;
    };
  };
}
