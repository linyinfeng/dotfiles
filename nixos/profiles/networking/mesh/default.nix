{ config, lib, ... }:
let
  cfg = config.networking.mesh;
  inherit (config.networking) hostName;
  inherit (config.lib.self) data;
  inherit (config.networking.hostsData) indexedHosts;
  mkHost = name: hostData: {
    # resolved by /etc/hosts
    connection.endpoint =
      if (lib.length (hostData.endpoints_v4 ++ hostData.endpoints_v6) != 0) then
        "${name}.endpoints.li7g.com"
      else
        null;
    ipsec.xfrmInterfaceId = 100000 + lib.elemAt hostData.host_indices 0;
  };
  ipv4OnlyHosts = [ ];
  bandwidthLimitedHosts = [ ];
in
lib.mkMerge [
  { networking.mesh.enable = config.networking.hostsData.indexed; }
  (lib.mkIf cfg.enable {
    networking.mesh = {
      hosts = lib.mapAttrs mkHost indexedHosts;
      thisHost.ipsec.initiate = if lib.elem hostName ipv4OnlyHosts then "ipv4" else "ipv6";
      routingTable = {
        id = config.routingTables.mesh;
        priority = config.routingPolicyPriorities.mesh;
      };
      ipsec = {
        enable = true;
        caCert = data.ca_cert_pem;
        hostCert = data.hosts.${hostName}.ike_cert_pem;
        hostCertKeyFile = config.sops.secrets."ike_private_key_pem".path;
      };
      bird.babelInterfaceConfig = ''
        ${lib.optionalString (!indexedHosts ? ${hostName} || lib.elem hostName bandwidthLimitedHosts) ''
          rxcost 200;
        ''}
        rtt cost 1024;
        rtt max 1024 ms;
      '';
      extraInterfaces = lib.optionalAttrs config.services.zerotierone.enable {
        "${config.passthru.zerotierInterfaceName}" = {
          type = "tunnel";
          extraConfig = cfg.bird.babelInterfaceConfig;
        };
      };
      # not working because tailscale does not support multicast
      # since tailscale is working on L3, multicast is unlikely to be supported
      # https://github.com/tailscale/tailscale/issues/1013
      # // lib.optionalAttrs config.services.tailscale.enable {
      #   "${config.passthru.tailscaleInterfaceName}" = {
      #     type = "tunnel";
      #     extraConfig = cfg.bird.babelInterfaceConfig;
      #   };
      # };
    };
    sops.secrets."ike_private_key_pem" = {
      terraformOutput = {
        enable = true;
        perHost = true;
      };
      restartUnits = [ "strongswan-swanctl.service" ];
    };
  })
]
