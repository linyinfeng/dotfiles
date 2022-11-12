{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    cachix
    nix-prefetch-scripts
    nix-prefetch-github
    nixpkgs-fmt
    nixpkgs-lint
    nixpkgs-review
    nix-update
    nixfmt
    cabal2nix
    patchelf
  ];
  programs.nix-index.enable = true;
  services.lorri.enable = true;

  home.global-persistence.directories = [
    ".config/cachix"
    ".cache/nix"
    ".cache/lorri"
  ];

  home.file = lib.mkIf (pkgs ? nix-index-database && pkgs.nix-index-database != null) {
    ".cache/nix-index/files".source = pkgs.nix-index-database;
  };
}
