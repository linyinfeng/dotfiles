{ config, pkgs, ... }:
let
  steamFontsDir = pkgs.symlinkJoin {
    name = "steam-fonts-dir";
    paths = config.fonts.packages;
  };
  steamFonts = pkgs.runCommand "steam-fonts" { preferLocalBuild = true; } ''
    mkdir -p "$out/share"
    ln -s "${steamFontsDir}" "$out/share/fonts"
  '';
in
{
  programs.steam.fontPackages = [ steamFonts ];
}
