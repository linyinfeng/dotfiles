{ pkgs, ... }:
{
  programs.noctalia = {
    enable = true;
    recommendedServices.enable = true;
  };

  programs.dconf.enable = true;

  services = {
    udisks2.enable = true;

    displayManager.noctalia-greeter = {
      enable = true;
      settings.keyboard.layout = "us";
    };
  };

  environment.systemPackages = [
    pkgs.dconf
    pkgs.glib
    pkgs.gsettings-desktop-schemas
  ];
}
