{ profiles, config, ... }:
let
  inherit (config.networking) hostName;
in
{
  imports = [
    profiles.services.frp-token
  ];
  services.frp.instances."server" = {
    enable = true;
    role = "server";
    settings = {
      bindAddr = "::1";
      proxyBindAddr = "::";
      bindPort = config.ports.frp;
      auth.token = "{{ .Envs.FRP_TOKEN }}";
      allowPorts = [
        {
          start = config.ports.frp-min;
          end = config.ports.frp-max;
        }
      ];
      log.level = "info";
    };
    environmentFiles = [ config.sops.templates."frp-token-env".path ];
  };
  services.nginx.virtualHosts."frp-${hostName}.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/" = {
      proxyPass = "http://[::1]:${toString config.ports.frp}";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_read_timeout 1h;
        proxy_send_timeout 1h;
      '';
    };
  };
  networking.firewall.allowedTCPPortRanges = [
    {
      from = config.ports.frp-min;
      to = config.ports.frp-max;
    }
  ];
  networking.firewall.allowedUDPPortRanges = [
    {
      from = config.ports.frp-min;
      to = config.ports.frp-max;
    }
  ];
}
