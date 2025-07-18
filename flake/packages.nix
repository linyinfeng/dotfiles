{ self, ... }:
{
  perSystem =
    {
      self',
      lib,
      pkgs,
      ...
    }:
    {
      packages = self.lib.flattenTree {
        setFilter = s: s.recurseForDerivations or false;
        leafFilter = lib.isDerivation;
      } (lib.recurseIntoAttrs (pkgs.callPackage ../packages { }));
      checks = lib.mapAttrs' (name: p: lib.nameValuePair "package/${name}" p) self'.packages;
    };
}
