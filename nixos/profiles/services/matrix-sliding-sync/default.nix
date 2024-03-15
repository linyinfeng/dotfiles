{ config, ... }:
{
  services.matrix-sliding-sync = {
    enable = true;
    environmentFile = config.sops.templates."sliding-sync-env".path;
    settings = {
      SYNCV3_BINDADDR = "127.0.0.1:${toString config.ports.matrix-sliding-sync}";
      SYNCV3_SERVER = "https://matrix.li7g.com";
    };
  };
  sops.templates."sliding-sync-env".content = ''
    SYNCV3_SECRET=${config.sops.placeholder."syncv3_secret"}
  '';
  sops.secrets."syncv3_secret" = {
    terraformOutput.enable = true;
    restartUnits = [ "matrix-sliding-sync.service" ];
  };

  services.nginx.virtualHosts."matrix-syncv3.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/".proxyPass = "http://127.0.0.1:${toString config.ports.matrix-sliding-sync}";
  };
}
