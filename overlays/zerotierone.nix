# TODO workaround for https://github.com/NixOS/nixpkgs/issues/192056
final: prev: {
  zerotierone = prev.zerotierone.overrideAttrs (old: {
    cargoDeps = final.rustPlatform.importCargoLock {
      lockFile = final.fetchurl {
        url = "https://raw.githubusercontent.com/zerotier/ZeroTierOne/${old.version}/zeroidc/Cargo.lock";
        sha256 = "sha256-pn7t7udZ8A72WC9svaIrmqXMBiU2meFIXv/GRDPYloc=";
      };
      outputHashes = {
        "jwt-0.16.0" = "sha256-P5aJnNlcLe9sBtXZzfqHdRvxNfm6DPBcfcKOVeLZxcM=";
      };
    };
  });
}
