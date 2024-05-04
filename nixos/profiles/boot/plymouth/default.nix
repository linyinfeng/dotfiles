{ config, ... }:
{
  boot.plymouth = {
    enable = true;
    theme = "bgrt"; # boot graphics resource table
    font = "${config.passthru.iosevka-yinfeng}/share/fonts/truetype/Iosevkayinfeng-Regular.ttf";
  };
  boot.kernelParams = [ "quiet" ];
}
