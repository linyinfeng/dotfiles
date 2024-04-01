{ pkgs, ... }:

{
  home.packages = with pkgs; [ logseq ];
  home.global-persistence.directories = [
    ".config/Logseq"
    ".logseq"
  ];
}
