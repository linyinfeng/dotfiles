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
    cabal2nix
    patchelf
    manix
  ];

  home.global-persistence.directories = [
    ".config/cachix"
    ".cache/nix-index"
  ];
}
