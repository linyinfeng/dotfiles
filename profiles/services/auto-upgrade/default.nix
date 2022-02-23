{ config, lib, ... }:

{
  system.autoUpgrade = {
    enable = true;
    flake = "github:linyinfeng/dotfiles/tested";
    allowReboot = true;
    dates = "04:00";
    randomizedDelaySec = "30min";
    flags = [ "--refresh" "--verbose" ];
  };
  systemd.services.nixos-upgrade.environment =
    lib.mkIf (config.networking.fw-proxy.enable)
      config.networking.fw-proxy.environment;

  services.scheduled-reboot = {
    enable = true;
    calendar = "04:00";
  };
}
