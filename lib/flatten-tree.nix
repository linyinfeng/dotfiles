{ lib }:
let
  mkNewPrefix =
    prefix: name:
    { separator, mapper }:
    "${if prefix == "" then "" else "${prefix}${separator}"}${mapper name}";
  flattenTree' =
    {
      leafFilter ? _: true,
      setFilter ? _: true,
      separator ? "/",
      mapper ? x: x,
    }@settings:
    prefix: remain:
    if lib.isAttrs remain && setFilter remain then
      lib.flatten (
        lib.mapAttrsToList (
          name: value: flattenTree' settings (mkNewPrefix prefix name { inherit separator mapper; }) value
        ) remain
      )
    else if leafFilter remain then
      [ (lib.nameValuePair prefix remain) ]
    else
      [ ];
in
settings: tree: lib.listToAttrs (flattenTree' settings "" tree)
