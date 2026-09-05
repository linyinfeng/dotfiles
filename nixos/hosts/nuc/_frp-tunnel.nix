{ config, ... }:
let
  tokenPath = config.sops.secrets."frp_token".path;
in
{
  sops.secrets."frp_token" = {
    terraformOutput.enable = true;
    mode = "0444"; # frp runs as DynamicUser
    restartUnits = [ "frp.service" ];
  };

  services.frp.instances."" = {
    enable = true;
    role = "server";
    settings = {
      bindAddr = "127.0.0.1";
      bindPort = config.ports.frp;
      auth.tokenSource = {
        type = "file";
        file.path = tokenPath;
      };
      allowPorts = [ { single = config.ports.frp-ssh; } ];
      log.level = "info";
    };
  };

  services.nginx.virtualHosts."xps8930-frp.li7g.com" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.ports.frp}";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_read_timeout 1h;
        proxy_send_timeout 1h;
      '';
    };
  };
}
