{ pkgs, ... }:
{
  home.packages = with pkgs; [
    racket
  ];

  home.global-persistence.directories = [
    ".rustup"
    ".cargo"
    ".cabal"
    ".wrangler"
    ".elan"

    ".config/racket"
    ".local/share/racket"

    "Source"
    "Local"
  ];
}
