{ config, ... }:

{
  services.nginx.virtualHosts."sicp-tutorials.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/".root = "/var/www/sicp-tutorials";
  };
}
