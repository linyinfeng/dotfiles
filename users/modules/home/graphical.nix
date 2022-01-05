{ config, lib, ... }:

let
  cfg = config.home.graphical;
  sysCfg = config.passthrough.systemConfig;

  sysGraphical = sysCfg.services.xserver.enable;
in

with lib;
{
  options.home.graphical = lib.mkOption {
    type = types.bool;
    description = ''
      Whether to enable graphical applications.
    '';
  };

  config = mkIf (sysCfg != null) {
    home.graphical = lib.mkDefault sysGraphical;
  };
}
