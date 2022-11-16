final: prev: {
  sources = final.callPackage (import ./_sources/generated.nix) { };
}
