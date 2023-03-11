{
  inputs,
  lib,
}:
lib.makeExtensible (self: {
  data = lib.importJSON ./data/data.json;
  flakeStateVersion = lib.importJSON ./state-version.json;
  buildModuleList = import ./build-module-list.nix {inherit inputs lib;};
})
