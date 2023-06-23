{
  config,
  lib,
  ...
}: let
  inherit (config.networking) hostName;
  cfg = config.services.nginx;
in {
  options = {
    services.nginx.openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };
  config = lib.mkMerge [
    {
      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        recommendedOptimisation = true;
        recommendedGzipSettings = true;

        virtualHosts."${hostName}.*" = {
          default = true;
          serverAliases = ["localhost.*"];
        };
      };

      networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [cfg.defaultHTTPListenPort cfg.defaultSSLListenPort];
      networking.firewall.allowedUDPPorts = lib.mkIf cfg.openFirewall [cfg.defaultSSLListenPort];
    }

    (lib.mkIf config.security.acme.acceptTerms {
      services.nginx.virtualHosts."${hostName}.*" = {
        forceSSL = true;
        useACMEHost = "main";
      };
    })
  ];
}
