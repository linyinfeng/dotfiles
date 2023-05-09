{
  config,
  lib,
  ...
}: {
  services.bird-lg.frontend = {
    enable = true;
    listenAddress = "127.0.0.1:${toString config.ports.bird-lg-frontend}";
    netSpecificMode = "dn42";
    domain = "dn42.li7g.com";
    proxyPort = config.ports.bird-lg-proxy;
    servers =
      lib.mapAttrsToList (_: hostCfg: hostCfg.name)
      config.networking.dn42.autonomousSystem.mesh.hosts;
  };
  services.nginx.virtualHosts."bird-lg.*" = {
    forceSSL = true;
    useACMEHost = "main";
    locations."/".proxyPass = "http://${config.services.bird-lg.frontend.listenAddress}";
  };
}
