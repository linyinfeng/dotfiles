{ pkgs, ... }:
{
  services.angrr = {
    enable = true;
    period = "7d";
    logLevel = "debug";
  };
  environment.systemPackages = with pkgs; [ angrr ];
}
