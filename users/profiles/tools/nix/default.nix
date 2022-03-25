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
    nixfmt
    cabal2nix
    patchelf
  ];

  home.global-persistence.directories = [
    ".config/cachix"
    ".cache/nix"
    ".cache/nix-index"
  ];
}
