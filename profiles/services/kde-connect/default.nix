{ ... }:

let
  portRange = {
    from = 1714;
    to = 1764;
  };
in
{
  networking.firewall = {
    allowedTCPPortRanges = [ portRange ];
    allowedUDPPortRanges = [ portRange ];
  };
}
