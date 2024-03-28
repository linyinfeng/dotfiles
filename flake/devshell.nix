{ config, ... }:
let
  flakeCfg = config;
in
{
  perSystem =
    {
      config,
      self',
      system,
      lib,
      pkgs,
      ...
    }:
    if lib.elem system flakeCfg.devSystems then
      {
        imports = [ ../devshell ];
        checks = lib.mapAttrs' (name: drv: lib.nameValuePair "devShells/${name}" drv) self'.devShells;
      }
    else
      {
        checks."no-devshells" =
          assert lib.assertMsg (config.devshells == { }) ''
            system `${system}` is not a dev system but have non-empty devshells
          '';
          pkgs.eval-only-check;
      };
}
