{ pkgs, ... }:

{
  home.packages = with pkgs; [
    cachix
    nix-prefetch-scripts
    nix-prefetch-github
    nixpkgs-fmt
    nix-index
    nix-update
    nixopsUnstable
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
