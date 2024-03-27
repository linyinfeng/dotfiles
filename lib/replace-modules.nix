{ lib }:
{
  fromNixpkgs ? null,
  from ? "${fromNixpkgs}/nixos/modules",
  modules,
}:

{
  disabledModules = modules;
  imports = lib.lists.map (m: "${from}/${m}") modules;
}
