{
  self,
  lib,
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
in {
  flake.checks = hostToplevels;
}
