{
  config,
  lib,
  ...
}: let
  # only show servers with endpoints
  hostFilter = _name: hostCfg: (hostCfg.endpointsV4 ++ hostCfg.endpointsV6) != [];
in {
  services.bird-lg.frontend = {
    enable = true;
    listenAddress = "127.0.0.1:${toString config.ports.bird-lg-frontend}";
    netSpecificMode = "dn42";
    domain = "ts.li7g.com";
    proxyPort = config.ports.bird-lg-proxy;
    whois = "whois.dn42";
    servers =
      lib.mapAttrsToList (_: hostCfg: hostCfg.name)
      (lib.filterAttrs hostFilter config.networking.dn42.autonomousSystem.mesh.hosts);
    protocolFilter = [];
    titleBrand = "li7g.com";
    navbar.allServers = "ALL";
  };
  services.nginx.virtualHosts."bird-lg.*" = {
    forceSSL = true;
    useACMEHost = "main";
    locations."/".proxyPass = "http://${config.services.bird-lg.frontend.listenAddress}";
  };
}
