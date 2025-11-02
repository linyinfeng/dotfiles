{ pkgs, ... }:
let
  steamFonts = pkgs.symlinkJoin {
    name = "steam-fonts";
    paths = with pkgs; [
      source-han-serif
      source-han-sans
      noto-fonts-color-emoji
      wqy_zenhei
      wqy_microhei
    ];
  };
in
{
  programs.steam.fontPackages = [ steamFonts ];
}
