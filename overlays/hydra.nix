# TODO remove after hydra being fixed in nixos-unstable
channels: final: prev:
let
  withSelectedNix = channels.nickpkgs.hydra-unstable.override {
    nix = final.nixVersions.selected;
  };
  nucSystemOnly = withSelectedNix.overrideAttrs (old: {
    meta.platforms = [ "x86_64-linux" ];
  });
in
{
  hydra-unstable = nucSystemOnly;
}
