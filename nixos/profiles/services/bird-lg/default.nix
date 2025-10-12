{ config, lib, ... }:
let
  # only show servers with endpoints
  inherit (config.lib.self) data;
  hostFilter = name: (data.hosts.${name}.endpoints_v4 ++ data.hosts.${name}.endpoints_v6) != [ ];
in
{
  services.bird-lg.frontend = {
    enable = true;
    listenAddresses = "127.0.0.1:${toString config.ports.bird-lg-frontend}";
    netSpecificMode = "dn42";
    domain = "ts.li7g.com";
    proxyPort = config.ports.bird-lg-proxy;
    whois = "whois.dn42";
    servers = lib.filter hostFilter (lib.attrNames config.networking.dn42.autonomousSystem.hosts);
    protocolFilter = [ ];
    titleBrand = "li7g.com";
    navbar.allServers = "ALL";
  };
  services.nginx.virtualHosts."bird-lg.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/".proxyPass = "http://${config.services.bird-lg.frontend.listenAddresses}";
  };
}
