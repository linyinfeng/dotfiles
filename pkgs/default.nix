final: prev: {
  sources = prev.callPackage (import ./_sources/generated.nix) { };
}
