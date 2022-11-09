final: prev: {
  sources = final.callPackage (import ./_sources/generated.nix) { };
  minio-latest = final.callPackage (import ./minio-latest.nix) { };
}
