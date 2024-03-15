{ pkgs, ... }:
{
  services.angrr = {
    enable = true;
    period = "7d";
    dates = "03:00";
  };
  environment.systemPackages = with pkgs; [ angrr ];
}
