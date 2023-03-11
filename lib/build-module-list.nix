{
  inputs,
  lib,
}: let
  inherit (inputs.digga.lib) rakeLeaves flattenTree;
in
  dir:
    lib.attrValues (flattenTree (rakeLeaves dir))
