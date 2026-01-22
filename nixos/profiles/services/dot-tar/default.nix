{ config, ... }:
{
  services.nginx.virtualHosts."tar.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.ports.dot-tar}";
    };
  };
  services.dot-tar = {
    enable = true;

    config = {
      release = {
        port = config.ports.dot-tar;
        authority_allow_list = [
          "github.com"
          "gitlab.gnome.org"
        ];
      };
    };
  };
}
