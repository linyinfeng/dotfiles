{ config, lib, ... }:

let
  cfg = config.passthrough;
in

with lib;
{
  options.passthrough = {
    systemConfig = lib.mkOption {
      type = with types; nullOr attrs;
      default = null;
      description = ''
        Full system configuration.
      '';
    };
  };
}
