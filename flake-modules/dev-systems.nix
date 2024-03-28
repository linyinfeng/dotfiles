{
  config,
  lib,
  flake-parts-lib,
  ...
}:
let
  inherit (flake-parts-lib) mkPerSystemOption;
in
{
  options = {
    devSystems = lib.mkOption {
      type = with lib.types; listOf str;
      default = config.systems;
    };
    perSystem = mkPerSystemOption (
      { system, ... }:
      {
        _file = ./dev-systems.nix;
        options.isDevSystem = lib.mkOption {
          type = lib.types.bool;
          default = lib.elem system config.devSystems;
          readOnly = true;
        };
      }
    );
  };
}
