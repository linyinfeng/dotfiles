{ self, lib }:
let
  inherit (self) flattenTree rakeLeaves;
in
dir: lib.attrValues (flattenTree { } (rakeLeaves dir))
