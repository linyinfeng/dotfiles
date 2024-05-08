{ pkgs, ... }:
{
  services.udev.packages = with pkgs; [ logitech-udev-rules ];
  environment.systemPackages = with pkgs; [ solaar ];
}
