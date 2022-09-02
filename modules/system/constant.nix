{ config, lib, ... }:

let
  cfg = config.system.constant;
in
{
  options.system.constant = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      build a system with "constant" configuration revision
    '';
  };
  config = lib.mkIf cfg {
    system.configurationRevision = lib.mkForce null;
    nix.registry.self = lib.mkForce {
      exact = false;
      from = {
        id = "self";
        type = "indirect";
      };
      to = {
        type = "github";
        owner = "linyinfeng";
        repo = "dotfiles";
      };
    };
  };
}
