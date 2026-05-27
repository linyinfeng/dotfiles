{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ probe-rs-tools ];
  services.udev.packages = with pkgs; [
    probe-rs-tools
  ];
}
