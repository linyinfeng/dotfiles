{ pkgs, ... }:
{
  boot.plymouth = {
    enable = true;
    theme = "bgrt"; # boot graphics resource table
    font = "${pkgs.iosevka-yinfeng}/share/fonts/truetype/Iosevkayinfeng-Regular.ttf";
  };
  boot.kernelParams = [ "quiet" ];
}
