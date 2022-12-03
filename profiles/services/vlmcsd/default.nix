{ config, ... }:

let
  port = config.ports.vlmcsd;
in
{
  services.vlmcsd = {
    enable = true;
    extraOptions = "-L 0.0.0.0:${toString port} -L [::]:${toString port}";
  };

  networking.firewall.allowedTCPPorts = [
    port
  ];
}
