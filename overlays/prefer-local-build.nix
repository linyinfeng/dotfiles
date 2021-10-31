final: prev:

let
  inherit (final) lib;
  jbPreferLocalBuild = oldAttrs:
    if !(oldAttrs.meta.license.free ? true) then {
      preferLocalBuild = true;
    } else { };
  addPreferLocalBuild = oldAttrs:
    assert !(oldAttrs ? preferLocalBuild); {
      preferLocalBuild = true;
    };
in
{
  # TODO before https://github.com/NixOS/nixpkgs/pull/143807
  jetbrains = lib.mapAttrs
    (name: p:
      if lib.isDerivation p && name != "jdk"
      then p.overrideAttrs jbPreferLocalBuild
      else p)
    prev.jetbrains;
}
