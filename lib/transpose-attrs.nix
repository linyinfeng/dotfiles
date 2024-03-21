{ lib }:

attrs:

let
  list = lib.fold (
    sys: l: lib.lists.map (pair: pair // { system = sys.name; }) (lib.attrsToList sys.value) ++ l
  ) [ ] (lib.attrsToList attrs);
in
lib.fold (
  item: transposed: lib.recursiveUpdate transposed { ${item.name}.${item.system} = item.value; }
) { } list
