{ pkgs, ... }:
let
  steamFonts = pkgs.symlinkJoin {
    name = "steam-fonts";
    paths = with pkgs; [
      source-han-serif
      source-han-sans
      noto-fonts-emoji
    ];
  };
in
{
  programs.steam.fontPackages = [ steamFonts ];
}
