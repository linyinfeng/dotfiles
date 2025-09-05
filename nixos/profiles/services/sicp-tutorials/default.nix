{ config, ... }:

{
  services.nginx.virtualHosts."sicp-tutorials.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/".root = "/var/www/sicp-tutorials";
    extraConfig = ''
      auth_basic "sicp tutorials";
      auth_basic_user_file ${config.sops.templates."sicp-tutorials-auth-file".path};
    '';
  };
  systemd.services.nginx.restartTriggers = [ config.sops.templates."sicp-tutorials-auth-file".file ];
  sops.templates."sicp-tutorials-auth-file" = {
    content = ''
      sicp:${config.sops.placeholder."sicp_tutorials_hashed_password"}
    '';
    owner = config.users.users.nginx.name;
  };
  sops.secrets."sicp_tutorials_hashed_password" = {
    terraformOutput.enable = true;
    restartUnits = [ "nginx.service" ];
  };
}
