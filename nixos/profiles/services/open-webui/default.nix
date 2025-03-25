{ config, ... }:

{
  inherit (config.networking) hostName;
  services.open-webui = {
    enable = true;
    port = config.ports.open-webui;
    environment = {
      OLLAMA_BASE_URL = "http://127.0.0.1:${toString config.services.ollama.port}";
    };
    # // lib.optionalAttrs config.networking.fw-proxy.enable config.networking.fw-proxy.environment;
  };

  services.nginx.virtualHosts."${hostName}.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/open-webui/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.open-webui.port}";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_buffering off;
      '';
    };
  };
}
