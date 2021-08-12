{ config, lib, ... }:

# network is not available in vm-test
lib.mkIf (!config.system.is-vm-test) {
  services.tailscale.enable = true;
  environment.global-persistence.directories = [
    "/var/lib/tailscale"
  ];
  # no need to open ports
  networking.firewall.allowedUDPPorts = [
    # config.services.tailscale.port
  ];
}
