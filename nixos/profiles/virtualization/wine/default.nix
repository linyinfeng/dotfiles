{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    wineWowPackages.staging
    winetricks
  ];

  environment.global-persistence.user.directories = [ ".wine" ];
}
