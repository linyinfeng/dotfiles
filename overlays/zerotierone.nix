# TODO workaround for https://github.com/NixOS/nixpkgs/issues/192056
final: prev: {
  zerotierone = prev.zerotierone.overrideAttrs (old: {
    cargoDeps = final.rustPlatform.importCargoLock {
      lockFile = ./zerotierone-cargo.lock;
      outputHashes = {
        "jwt-0.16.0" = "sha256-P5aJnNlcLe9sBtXZzfqHdRvxNfm6DPBcfcKOVeLZxcM=";
      };
    };
  });
}
