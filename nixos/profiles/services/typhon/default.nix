{ config, ... }:
{
  services.typhon = {
    enable = true;
    hashedPasswordFile = config.sops.secrets."typhon_hashed_password".path;
  };

  systemd.services.typhon = {
    environment = {
      LEPTOS_SITE_ADDR = "[::1]:${toString config.ports.typhon}";
    };
  };

  services.nginx.virtualHosts."typhon.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/" = {

      proxyPass = "http://[::1]:${toString config.ports.typhon}";
      recommendedProxySettings = true;
    };
  };

  sops.secrets."typhon_hashed_password" = {
    terraformOutput.enable = true;
    owner = config.users.users.typhon.name;
    group = config.users.groups.typhon.name;
    restartUnits = [ "typhon.service" ];
  };
}
