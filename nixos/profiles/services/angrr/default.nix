{ pkgs, ... }:
{
  services.angrr = {
    enable = true;
    period = "7d";
  };
  environment.systemPackages = with pkgs; [ angrr ];
}
