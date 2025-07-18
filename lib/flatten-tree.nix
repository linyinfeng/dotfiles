{ lib }:
let
  mkNewPrefix = prefix: name: "${if prefix == "" then "" else "${prefix}/"}${name}";
  flattenTree' =
    {
      leafFilter ? _: true,
      setFilter ? _: true,
    }@settings:
    prefix: remain:
    if lib.isAttrs remain && setFilter remain then
      lib.flatten (
        lib.mapAttrsToList (name: value: flattenTree' settings (mkNewPrefix prefix name) value) remain
      )
    else if leafFilter remain then
      [ (lib.nameValuePair prefix remain) ]
    else
      [ ];
in
settings: tree: lib.listToAttrs (flattenTree' settings "" tree)
