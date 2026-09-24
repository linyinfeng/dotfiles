{ ... }:
{
  world.profiles = {
    networking = {
      avahi.enable = true;
      dn42.enable = true;
      endpoints.enable = true;
      firewall.enable = true;
      iproute2.enable = true;
      mesh.enable = true;
      networkd.enable = true;
      resolved.enable = true;
      tailscale.enable = true;
      zerotier.enable = true;
    };
    security = {
      fail2ban.enable = true;
      firewall.enable = true;
    };
    services.vnstatd.enable = true;
  };
}
