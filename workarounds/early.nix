# Workarounds that must be visible to the overlays in ../flake/nixpkgs.nix
# themselves, because those overlays build on the fixed attributes.
{ channelsOf }:
let
  # TODO wait for NixOS/nixpkgs#573479 in nixos-unstable
  dropSphinxMan =
    drv:
    drv.overrideAttrs (old: {
      outputs = builtins.filter (o: o != "man") (old.outputs or [ "out" ]);
      sphinxBuilders = builtins.filter (b: b != "man") (old.sphinxBuilders or [ "html" ]);
    });
in
[
  (final: _prev: {
    # maintained packages
    godns = (channelsOf final).latest.godns;
  })
  (_final: prev: {
    reuse = dropSphinxMan prev.reuse;
  })
]
