{ config, lib, nixosConfig, ... }:

let
  cfg = config.home.graphical;
  sysGraphical = nixosConfig.services.xserver.enable;
in

with lib;
{
  options.home.graphical = lib.mkOption {
    type = types.bool;
    description = ''
      Whether to enable graphical applications.
    '';
  };

  config = {
    home.graphical = lib.mkDefault sysGraphical;
  };
}
