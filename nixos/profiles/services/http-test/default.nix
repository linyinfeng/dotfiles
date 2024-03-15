{ config, ... }:
{
  services.nginx.virtualHosts."http-test.*" = {
    addSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/".extraConfig = ''
      add_header Content-Type text/plain;
      return 200 "$scheme";
    '';
  };
}
