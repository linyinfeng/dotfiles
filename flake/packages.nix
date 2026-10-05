{ self, ... }:
{
  perSystem =
    {
      config,
      self',
      lib,
      pkgs,
      ...
    }:
    let
      repoPackages = lib.recurseIntoAttrs (
        pkgs.callPackage ../packages { inherit (config) isDevSystem; }
      );
    in
    {
      packages = self.lib.flattenTree {
        setFilter = s: s.recurseForDerivations or false;
        leafFilter = lib.isDerivation;
      } repoPackages;
      checks = lib.mapAttrs' (name: p: lib.nameValuePair "package/${name}" p) self'.packages;
    };
}
