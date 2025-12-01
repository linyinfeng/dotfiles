{ lib, ... }:

{
  system.nixos-init.enable = lib.mkDefault true;
  # we still need activation scripts
  # system.activatable = false;
}
