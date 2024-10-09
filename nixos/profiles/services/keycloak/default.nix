{ config, ... }:
{
  services.keycloak = {
    enable = true;
    database = {
      # database will be automatically created by the keycloak module
      type = "postgresql";
      passwordFile = config.sops.secrets.keycloak_db_password.path;
    };
    settings = {
      hostname = "keycloak.li7g.com";
      proxy-headers = "xforwarded";
      http-host = "127.0.0.1";
      http-port = config.ports.keycloak;
    };
  };
  services.nginx.virtualHosts."keycloak.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/".proxyPass = "http://127.0.0.1:${toString config.ports.keycloak}";
  };
  sops.secrets."keycloak_db_password" = {
    terraformOutput.enable = true;
    restartUnits = [ "keycloak.service" ];
  };
}
