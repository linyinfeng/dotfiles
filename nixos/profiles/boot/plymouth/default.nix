{ pkgs, ... }:
{
  boot.plymouth = {
    enable = true;
    theme = "bgrt"; # boot graphics resource table
    font = "${pkgs.nerd-fonts.iosevka-term-slab}/share/fonts/truetype/NerdFonts/IosevkaTermSlab/IosevkaTermSlabNerdFontMono-Regular.ttf";
  };
  boot.kernelParams = [ "quiet" ];
}
