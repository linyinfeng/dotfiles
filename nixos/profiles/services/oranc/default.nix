{ config, ... }:
{
  services.oranc = {
    enable = true;
    listen = "127.0.0.1:${toString config.ports.oranc}";
  };
  services.nginx.virtualHosts."oranc.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/" = {
      proxyPass = "http://${config.services.oranc.listen}";
    };
  };
}
