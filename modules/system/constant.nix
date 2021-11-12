{ lib, ... }:

{
  options.system.constant = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      build a system with "constant" configuration revision
    '';
  };
  config = {
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
