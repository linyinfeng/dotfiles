{ config, ... }:
{
  services.portal = {
    host = "portal.li7g.com";
    client = {
      enable = true;
      ports.socks = config.ports.portal-socks;
      ports.http = config.ports.portal-http;
    };
  };
}
