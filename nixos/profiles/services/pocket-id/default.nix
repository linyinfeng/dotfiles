{ config, ... }:
let
  inherit (config.services.pocket-id) user;
  port = config.ports.pocket-id;
in
{
  services.pocket-id = {
    enable = true;
    settings = {
      UI_CONFIG_DISABLED = true;
      APP_URL = "https://id.li7g.com";
      TRUST_PROXY = true;
      HOST = "::1";
      PORT = port;
      DB_PROVIDER = "postgres";
      DB_CONNECTION_STRING = "host=/run/postgresql user=${user} database=${user}";
      SMTP_HOST = "smtp.li7g.com";
      SMTP_PORT = 587;
      SMTP_TLS = "starttls";
      SMTP_USER = "id@li7g.com";
      SMTP_FROM = "id@li7g.com";
      EMAIL_LOGIN_NOTIFICATION_ENABLED = true;
    };
    environmentFile = config.sops.templates."pocket-id-env".path;
  };
  services.postgresql = {
    enable = true;
    ensureUsers = [
      {
        name = user;
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [ user ];
  };
  # currently nothing
  sops.templates."pocket-id-env".content = ''
    SMTP_PASSWORD=${config.sops.placeholder."mail_password"}
  '';
  sops.secrets."mail_password" = {
    terraformOutput.enable = true;
    restartUnits = [ "pocket-id.service" ];
  };
  services.nginx.virtualHosts."id.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/" = {
      proxyPass = "http://[::1]:${toString port}";
      extraConfig = ''
        proxy_busy_buffers_size   512k;
        proxy_buffers   4 512k;
        proxy_buffer_size   256k;
      '';
    };
  };
}
