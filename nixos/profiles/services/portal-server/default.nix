{
  config,
  pkgs,
  ...
}: {
  services.nginx.virtualHosts."portal.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/" = {
      root = pkgs.element-web;
    };
  };
  services.portal = {
    host = "portal.li7g.com";
    nginxVirtualHost = "portal.*";
    server = {
      enable = true;
      internalPort = config.ports.portal-internal;
    };
  };
}
