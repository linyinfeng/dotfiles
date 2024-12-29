{ config, pkgs, ... }:
{
  assertions = [
    {
      assertion = config.services.resolved.enable;
      message = "requires mDNS support";
    }
  ];
  services.printing = {
    enable = true;
    drivers = with pkgs; [ ];
  };
}
