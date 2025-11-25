{ config, lib, ... }:

let
  cfg = config.system.bashless;
in
{
  options = {
    system.bashless.enable = lib.mkEnableOption "bashless activation" // {
      default = true;
    };
  };
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        system.nixos-init.enable = lib.mkDefault true;
        # we still need activation scripts
        # system.activatable = false;
      }
    ]
  );
}
