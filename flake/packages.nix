{ ... }:
{
  perSystem =
    { self', lib, ... }:
    {
      checks = lib.mapAttrs' (name: p: lib.nameValuePair "package/${name}" p) self'.packages;
    };
}
