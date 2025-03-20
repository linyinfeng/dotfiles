{
  config,
  pkgs,
  lib,
  ...
}:
let
  extraHostInfo = {
    fsn0 = {
      comment = null;
      provider = "Hetzner";
      location = [
        "Falkenstein"
        "Germany"
      ];
    };
    mtl0 = {
      comment = null;
      provider = "ServaRICA";
      location = [
        "Montreal"
        "Quebec"
        "Canada"
      ];
    };
    lax0 = {
      comment = null;
      provider = "RackNerd";
      location = [
        "Los Angeles"
        "United States"
      ];
    };
    hkg0 = {
      comment = null;
      provider = "JuHost";
      location = [
        "Hong Kong"
        "China"
      ];
    };
  };
  cfg = config.networking.dn42;
  asCfg = cfg.autonomousSystem;
  json = pkgs.formats.json { };
  inherit (config.lib.self) data;
  filterHost =
    name: _hostCfg: (data.hosts.${name}.endpoints_v4 ++ data.hosts.${name}.endpoints_v6) != [ ];
  mkHostInfo =
    name: hostCfg:
    lib.recursiveUpdate {
      dn42 = {
        addresses = {
          v4 = hostCfg.preferredAddressV4;
          v6 = hostCfg.preferredAddressV6;
        };
      };
      tunnel = {
        supported_types = config.passthru.dn42SupportedTunnelTypes;
        network = {
          addresses = {
            v4 = [ hostCfg.preferredAddressV4 ];
            v6 = [
              config.networking.dn42.bgp.peering.defaults.linkAddresses.v6.local
            ] ++ [ hostCfg.preferredAddressV6 ];
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
    } extraHostInfo.${name};
  info = {
    autonomous_system = {
      inherit (asCfg) number;
      cidrs = {
        v4 = asCfg.cidrV4;
        v6 = asCfg.cidrV6;
      };
    };
    hosts = lib.mapAttrs mkHostInfo (lib.filterAttrs filterHost asCfg.hosts);
  };
  siteRoot = pkgs.runCommandNoCC "dn42-site-root" { } ''
    mkdir -p $out
    cp "${json.generate "info.json" info}" $out/info.json
  '';
in
{
  services.nginx.virtualHosts."dn42.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    extraConfig = ''
      types { application/json json; }
    '';
    locations."= /".extraConfig = ''
      return 302 https://$host/info.json;
    '';
    locations."/".root = siteRoot;
  };
}
