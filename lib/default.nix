{ lib }:
lib.makeExtensible (self: {
  data = lib.importJSON ../data/data.json;
  overlayNullProtector = import ./overlay-null-protector.nix;
  flakeStateVersion = import ./state-version.nix;
})
