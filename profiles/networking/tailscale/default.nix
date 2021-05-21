{ config, ... }:

{
  services.tailscale.enable = true;
  environment.global-persistence.directories = [
    "/var/lib/tailscale"
  ];
  networking.firewall.allowedUDPPorts = [
    config.services.tailscale.port
  ];
}
