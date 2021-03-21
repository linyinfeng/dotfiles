{ pkgs, ... }:

{
  home.packages = with pkgs; [
    cachix
    nix-prefetch-scripts
    nix-prefetch-github
    nixpkgs-fmt
    nix-index
    nix-update
    nixops-flake
    cabal2nix
    carnix
    patchelf
    manix
  ];
}
