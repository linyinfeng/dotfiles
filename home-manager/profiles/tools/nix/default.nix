{ pkgs, ... }:
{
  home.packages = with pkgs; [
    cachix
    flat-flake
    nil
    nix-output-monitor
    nix-prefetch-scripts
    nix-prefetch-github
    nixpkgs-fmt
    nixpkgs-lint
    nixpkgs-review
    nix-update
    nix-melt
    nix-du
    nix-tree
    nixfmt
    cabal2nix
    patchelf
  ];

  programs.fish.interactiveShellInit = ''
    function nom --description "generic nix-output-manager wrapper"
      nix --log-format internal-json --verbose $argv &| command nom --json
    end
  '';

  home.global-persistence.directories = [
    ".config/cachix"
    ".cache/nix"
  ];
}
