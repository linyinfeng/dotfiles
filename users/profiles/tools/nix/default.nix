{ pkgs, ... }:

{
  home.packages = with pkgs; [
    cachix
    nix-prefetch-scripts
    nix-prefetch-github
    nixpkgs-fmt
    nixpkgs-lint
    nixpkgs-review
    nix-index
    nix-update
    nixops_unstable
    cabal2nix
    carnix
    patchelf
    manix
  ];

  home.global-persistence.directories = [
    ".nixops"
    ".config/cachix"
    ".cache/nix-index"
  ];
}
