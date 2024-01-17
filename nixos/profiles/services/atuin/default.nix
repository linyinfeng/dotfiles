{config, ...}:
let
  cfg = config.services.atuin;
in
{
  services.atuin = {
    enable = true;
    host = "127.0.0.1";
    port = config.ports.atuin;
    database.createLocally = true;
    openRegistration = false;
  };
  services.nginx.virtualHosts."atuin.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/".proxyPass = "http://${cfg.host}:${toString cfg.port}";
  };
}
