{ lib }:
lib.makeExtensible (self: {
  overlayNullProtector = import ./overlay-null-protector.nix;
})
