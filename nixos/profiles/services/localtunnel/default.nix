{ config, pkgs, ... }:
{
  systemd.services.localtunnel = {
    script = ''
      "${pkgs.nur.repos.linyinfeng.rlt}/bin/localtunnel" server \
        --domain lt.li7g.com \
        --port "${toString config.ports.localtunnel-endpoint}" \
        --proxy-port "${toString config.ports.localtunnel-request}"
    '';
    serviceConfig = {
      DynamicUser = true;
    };
    wantedBy = [ "multi-user.target" ];
  };
  services.nginx.virtualHosts."lt.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/".proxyPass = "http://127.0.0.1:${toString config.ports.localtunnel-request}";
  };
  services.nginx.virtualHosts."*.lt.li7g.com" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/".proxyPass = "http://127.0.0.1:${toString config.ports.localtunnel-endpoint}";
  };
}
