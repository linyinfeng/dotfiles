{ config, ... }:
{
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://ntfy.li7g.com";
      listen-http = "[::1]:${toString config.ports.ntfy}";
      auth-default-access = "deny-all";
    };
  };
  # https://docs.ntfy.sh/config/#nginxapache2caddy
  services.nginx.virtualHosts."ntfy.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/" = {
      proxyPass = "http://[::1]:${toString config.ports.ntfy}";
      proxyWebsockets = true;
      extraConfig = ''
        client_max_body_size 0; # stream request body to backend
      '';
    };
  };
  services.nginx.proxyTimeout = "3m";
}
