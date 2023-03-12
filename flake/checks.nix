{
  self,
  lib,
  withSystem,
  ...
}: let
  getHostToplevel = name: cfg: let
    inherit (cfg.pkgs.stdenv.hostPlatform) system;
  in {
    "${system}"."nixos/${name}" = cfg.config.system.build.toplevel;
  };
  hostToplevels =
    lib.fold lib.recursiveUpdate {}
    (lib.mapAttrsToList getHostToplevel self.nixosConfigurations);
  checks = hostToplevels;
  hydraMachine = "nuc";
  hydraSystem = self.nixosConfigurations.${hydraMachine}.pkgs.stdenv.hostPlatform.system;
  allChecks = withSystem hydraSystem ({pkgs, ...}:
    pkgs.linkFarm "all-checks"
    (lib.flatten (lib.mapAttrsToList
      (system:
        lib.mapAttrsToList (name: drv: {
          name = "${name}-${system}";
          path = drv;
        }))
      checks)));
in {
  flake.checks =
    lib.recursiveUpdate checks
    {
      "${hydraSystem}".all-checks = allChecks;
    };
}
