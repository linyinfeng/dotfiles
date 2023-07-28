{
  config,
  pkgs,
  ...
}: {
  services.nginx.virtualHosts."portal.*" = {
    forceSSL = true;
    useACMEHost = "main";
    locations."/" = {
      root = pkgs.element-web;
    };
  };
  services.portal = {
    host = "portal.li7g.com";
    nginxVirtualHost = "portal.*";
    server = {
      enable = true;
      internalPort = config.ports.portal-internal;
    };
  };
}
