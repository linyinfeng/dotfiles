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

  services.lorri.enable = true;

  home.global-persistence.directories = [
    ".config/cachix"
    ".cache/nix"
    ".cache/lorri"
  ];

  home.file.".cache/nix-index/files".source = pkgs.nix-index-database;
}
