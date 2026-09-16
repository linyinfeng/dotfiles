{ inputs, lib }:
let
  haumea = inputs.haumea.lib;
  loader = lib.const lib.id;
  transformer =
    cursor: dir:
    if dir ? default then
      let
        path = lib.concatStringsSep "/" cursor;
        extra = lib.remove "default" (lib.attrNames dir);
      in
      assert lib.assertMsg (extra == [ ]) ''
        rakeLeaves: ${path} is a leaf because it contains default.nix, but ${lib.concatStringsSep ", " extra} sits next to it.
        Move that into default.nix, or rename it with a leading underscore to have it ignored.
      '';
      dir.default
    else
      dir;
in
src: haumea.load { inherit src loader transformer; }
