final: prev: {
  sources = prev.callPackage (import ./_sources/generated.nix) { };

  nix-index-database = final.callPackage ./nix-index-database.nix { };
}
