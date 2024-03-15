{ config, ... }:
{
  services.portal = {
    host = "portal.li7g.com";
    client = {
      enable = true;
      port = config.ports.portal-socks;
    };
  };
}
