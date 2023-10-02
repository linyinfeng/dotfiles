{
  config,
  lib,
  ...
}: let
  cfg = config.networking.mesh;
  hostName = config.networking.hostName;
  data = config.lib.self.data;
  filteredHost = lib.filterAttrs (_: hostData: (lib.length hostData.host_indices != 0)) data.hosts;
  mkHost = name: hostData: {
    connection = {
      endpointsV4 = hostData.endpoints_v4;
      endpointsV6 = hostData.endpoints_v6;
    };
    ipsec = {
      xfrmInterfaceId = 100000 + lib.elemAt hostData.host_indices 0;
      initiate =
        if lib.elem name ipv4OnlyHosts
        then "ipv4"
        else "ipv6";
    };
  };
  ipv4OnlyHosts = ["shg0"];
in {
  networking.mesh = {
    enable = filteredHost ? ${hostName};
    hosts = lib.mapAttrs mkHost filteredHost;
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
      rtt cost 1024;
      rtt max 1024 ms;
    '';
    extraInterfaces =
      lib.optionalAttrs config.services.zerotierone.enable {
        "${config.passthru.zerotierInterfaceName}" = {
          type = "tunnel";
          extraConfig = cfg.bird.babelInterfaceConfig;
        };
      };
  };
  sops.secrets."ike_private_key_pem" = {
    sopsFile = config.sops-file.terraform;
    restartUnits = ["strongswan-swanctl.service"];
  };
}
