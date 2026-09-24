{ lib, ... }:
{
  world.profiles.networking.networkd.enable = lib.mkDefault true;
  world.profiles.networking.iproute2.enable = lib.mkDefault true;
  world.profiles.networking.firewall.enable = lib.mkDefault true;
  world.profiles.networking.avahi.enable = lib.mkDefault true;
  world.profiles.networking.resolved.enable = lib.mkDefault true;
  world.profiles.networking.tailscale.enable = lib.mkDefault true;
  world.profiles.networking.zerotier.enable = lib.mkDefault true;
  world.profiles.networking.mesh.enable = lib.mkDefault true;
  world.profiles.networking.dn42.enable = lib.mkDefault true;
  world.profiles.networking.endpoints.enable = lib.mkDefault true;
  world.profiles.security.fail2ban.enable = lib.mkDefault true;
  world.profiles.security.firewall.enable = lib.mkDefault true;
  world.profiles.services.vnstatd.enable = lib.mkDefault true;
}
