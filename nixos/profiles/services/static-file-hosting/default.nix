{ config, ... }:
{
  services.nginx.virtualHosts."static.*" = {
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/".root = "/var/www/static";
    extraConfig = ''
      autoindex on;
    '';
  };
  environment.global-persistence.directories = [ "/var/www/static" ];
}
