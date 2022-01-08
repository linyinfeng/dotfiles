{ config, lib, ... }:

{
  system.autoUpgrade = {
    enable = true;
    flake = "github:linyinfeng/dotfiles/tested";
    allowReboot = true;
    dates = "04:30";
    flags = [ "--verbose" ];
  };
  systemd.services.nixos-upgrade.environment =
    lib.mkIf (config.networking.fw-proxy.enable)
      config.networking.fw-proxy.environment;

  services.scheduled-reboot = {
    enable = true;
    calendar = "04:00";
  };
}
