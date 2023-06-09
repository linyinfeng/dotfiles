{lib}: pkgs: path: let
  inherit (pkgs.stdenv.hostPlatform) system;
  p = lib.attrByPath path null pkgs;
in
  lib.optional (p != null && lib.elem system p.meta.platforms) p
