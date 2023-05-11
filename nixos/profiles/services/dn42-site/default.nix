{
  config,
  pkgs,
  lib,
  ...
}: let
  extraHostInfo = {
    hil0 = {
      comment = null;
      provider = "Hetzner";
      location = "United States, Oregon, Hillsboro";
    };
    fsn0 = {
      comment = null;
      provider = "Hetzner";
      location = "Germany, Falkenstein";
    };
    mtl0 = {
      comment = null;
      provider = "ServaRICA";
      location = "Canada, Quebec, Montreal";
    };
    mia0 = {
      comment = "low performance machine (1C512M)";
      provider = "Vultr";
      location = "United States, Florida, Miami";
    };
    shg0 = {
      comment = "not available for peering";
      provider = "Tencent Cloud";
      location = "China, Shanghai";
    };
  };
  cfg = config.networking.dn42;
  asCfg = cfg.autonomousSystem;
  json = pkgs.formats.json {};
  data = config.lib.self.data;
  filterHost = name: hostCfg: (hostCfg.endpointsV4 ++ hostCfg.endpointsV6) != [];
  mkHostInfo = name: hostCfg: lib.recursiveUpdate {
    dn42 = {
      addresses = {
        v4 = hostCfg.addressesV4;
        v6 = hostCfg.addressesV6;
      };
    };
    tunnel = {
      supported_types = config.passthru.dn42SupportedTunnelTypes;
      network = {
        addresses = {
          v4 = hostCfg.addressesV4;
          v6 = [config.networking.dn42.bgp.peering.defaults.linkAddresses.v6.local] ++ hostCfg.addressesV6;
        };
      };
      # traffic_control = config.passthru.dn42.trafficControlTable.${name}.enable;
      wireguard = {
        endpoints = {
          v4 = hostCfg.endpointsV4;
          v6 = hostCfg.endpointsV6;
        };
        public_key = data.hosts.${name}.wireguard_public_key;
        port = "Last 5 digits of your ASN";
      };
    };
  } extraHostInfo.${name};
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
