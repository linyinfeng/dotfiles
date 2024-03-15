{ pkgs, ... }:
{
  hardware.rtl-sdr.enable = true;
  environment.systemPackages = with pkgs; [
    rtl-sdr
    soapysdr-with-plugins
  ];
}
