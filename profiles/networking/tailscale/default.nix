{ config, lib, ... }:

{
  services.tailscale.enable = true;
  # no need to open ports
  networking.firewall.allowedUDPPorts = [
    config.services.tailscale.port
  ];
  networking.firewall.trustedInterfaces = [
    "tailscale0"
  ];
}
