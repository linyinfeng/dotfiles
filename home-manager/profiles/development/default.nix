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

    ".config/racket"
    ".local/share/racket"

    "Source"
    "Local"
  ];
}
