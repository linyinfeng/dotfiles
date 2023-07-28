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
      location = ["Hillsboro" "Oregon" "United States"];
    };
    fsn0 = {
      comment = null;
      provider = "Hetzner";
      location = ["Falkenstein" "Germany"];
    };
    mtl0 = {
      comment = null;
      provider = "ServaRICA";
      location = ["Montreal" "Quebec" "Canada"];
    };
    mia0 = {
      comment = "low performance machine (1C512M)";
      provider = "Vultr";
      location = ["Miami" "Florida" "United States"];
    };
    shg0 = {
      comment = "not available for peering";
      provider = "Tencent Cloud";
      location = ["Shanghai" "China"];
    };
    hkg0 = {
      comment = null;
      provider = "JuHost";
      location = ["Hong Kong" "China"];
    };
  };
  cfg = config.networking.dn42;
  asCfg = cfg.autonomousSystem;
  json = pkgs.formats.json {};
  data = config.lib.self.data;
  filterHost = name: _hostCfg:
    (data.hosts.${name}.endpoints_v4
      ++ data.hosts.${name}.endpoints_v6)
    != [];
  mkHostInfo = name: hostCfg:
    lib.recursiveUpdate {
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
        traffic_control = config.passthru.dn42TrafficControlTable.${name}.enable;
        wireguard = {
          endpoints = {
            v4 = data.hosts.${name}.endpoints_v4;
            v6 = data.hosts.${name}.endpoints_v6;
          };
          public_key = data.hosts.${name}.wireguard_public_key;
          port = "Last 5 digits of your ASN";
        };
      };
    }
    extraHostInfo.${name};
  info = {
    autonomous_system = {
      number = asCfg.number;
      cidrs = {
        v4 = asCfg.cidrV4;
        v6 = asCfg.cidrV6;
      };
    };
    hosts = lib.mapAttrs mkHostInfo (lib.filterAttrs filterHost asCfg.hosts);
  };
  siteRoot = pkgs.runCommandNoCC "dn42-site-root" {} ''
    mkdir -p $out
    cp "${json.generate "info.json" info}" $out/info.json
  '';
in {
  services.nginx.virtualHosts."dn42.*" = {
    forceSSL = true;
    useACMEHost = "main";
    extraConfig = ''
      types { application/json json; }
    '';
    locations."= /".extraConfig = ''
      return 302 https://$host/info.json;
    '';
    locations."/".root = siteRoot;
  };
}
