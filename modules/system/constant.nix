{ lib, ... }:

{
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
}
