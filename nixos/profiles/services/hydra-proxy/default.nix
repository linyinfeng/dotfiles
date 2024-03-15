{ config, ... }:
{
  services.nginx.upstreams."hydra".servers = {
    "hydra.ts.li7g.com:${toString config.ports.https}" = { };
  };
  services.nginx.virtualHosts."hydra-proxy.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/" = {
      proxyPass = "https://hydra";
    };
  };
}
