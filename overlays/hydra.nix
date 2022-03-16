# TODO remove after hydra being fixed in nixos-unstable
channels: final: prev: {
  hydra-unstable = channels.nickpkgs.hydra-unstable.override {
    nix = final.nixVersions.selected;
  };
}
