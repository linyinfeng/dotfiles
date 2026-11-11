{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [ inputs.ncro.nixosModules.ncro ];

  # ncro's module defaults its package to the input's own build, but the
  # overlay replaces it with the sqlite-linked one (see workarounds/late.nix)
  services.ncro.package = lib.mkForce pkgs.ncro;
}
