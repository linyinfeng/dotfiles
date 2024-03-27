{ inputs, lib }:
lib.makeExtensible (self: {
  data = lib.importJSON ./data/data.json;
  flakeStateVersion = lib.importJSON ./state-version.json;
  buildModuleList = import ./build-module-list.nix { inherit self lib; };
  flattenTree = import ./flatten-tree.nix { inherit lib; };
  rakeLeaves = import ./rake-leaves.nix { inherit inputs lib; };
  optionalPkg = import ./optional-pkg.nix { inherit lib; };
  transposeAttrs = import ./transpose-attrs.nix { inherit lib; };
  cidr = import ./cidr.nix { inherit lib; };
  requireSystemFeatures = import ./require-system-features.nix { inherit lib; };
  requireBigParallel = self.requireSystemFeatures [ "big-parallel" ];
  replaceModules = import ./replace-modules.nix { inherit lib; };
  replaceModuleSimple = import ./replace-module-simple.nix { inherit (self) replaceModules; };
})
