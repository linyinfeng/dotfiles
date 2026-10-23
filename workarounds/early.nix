# Workarounds that must be visible to the overlays in ../flake/nixpkgs.nix
# themselves, because those overlays build on the fixed attributes.
{ channelsOf }:
let
  # qt 6.12's uic rejects the leading "::" of this .ui file's class names.
  fixMozc =
    drv:
    drv.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace src/gui/dictionary_tool/dictionary_tool.ui \
          --replace-fail "::mozc::" "mozc::"
      '';
    });
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
  (final: prev: {
    mozc = fixMozc prev.mozc;
    # built from the same source, and from the mozc it was instantiated with
    ibus-engines = prev.ibus-engines // {
      mozc = fixMozc prev.ibus-engines.mozc;
    };
    fcitx5-mozc = prev.fcitx5-mozc.override { inherit (final) mozc; };
    reuse = dropSphinxMan prev.reuse;
  })
]
