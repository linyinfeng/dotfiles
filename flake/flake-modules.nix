{lib, ...}: let
  modules = import ../flake-modules;
in {
  flake.flakeModules = modules;
  imports = lib.attrValues modules;
}
