{ config, lib, ... }:

lib.mkIf
  config.services.xserver.desktopManager.plasma5.enable
{
  services.xserver = {
    enable = true;
    displayManager.sddm.enable = true;
  };

  environment.global-persistence.user = {
    directories = [
      ".local/share/applications"
      ".local/share/Trash"
    ];
    files = [
      ".face"
    ];
  };
}
