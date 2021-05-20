{ ... }:

let
  port = 40044;
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
