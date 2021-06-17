{ ... }:

{
  services.samba.enable = true;
  networking.firewall.allowedTCPPorts = [ 139 445 ];
  networking.firewall.allowedUDPPorts = [ 137 138 ];
  environment.global-persistence.directories = [
    "/var/lib/samba"
  ];
}
