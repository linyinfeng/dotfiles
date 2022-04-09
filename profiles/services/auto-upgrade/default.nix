{ config, lib, ... }:

{
  # TODO nuc down
  system.autoUpgrade = {
    enable = false;
    flake = "github:linyinfeng/dotfiles/tested";
    allowReboot = true;
    dates = "04:00";
    randomizedDelaySec = "30min";
    flags = [ "--refresh" ];
  };
  systemd.services.nixos-upgrade.environment =
    lib.mkIf (config.networking.fw-proxy.enable)
      config.networking.fw-proxy.environment;

  services.scheduled-reboot = {
    enable = true;
    calendar = "04:00";
  };
}
