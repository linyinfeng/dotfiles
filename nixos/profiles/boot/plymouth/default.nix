{ pkgs, ... }:
{
  boot.plymouth = {
    enable = true;
    font = "${pkgs.nerd-fonts.iosevka-term-slab}/share/fonts/truetype/NerdFonts/IosevkaTermSlab/IosevkaTermSlabNerdFontMono-Regular.ttf";
  };
  boot.kernelParams = [ "quiet" ];
}
