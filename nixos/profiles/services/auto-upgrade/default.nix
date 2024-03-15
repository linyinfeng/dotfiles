{ config, lib, ... }:
let
  hostName = config.networking.hostName;
in
{
  system.autoUpgrade = {
    enable = true;
    flake = "github:linyinfeng/dotfiles/nixos-tested-${hostName}";
    allowReboot = true;
    dates = "04:00";
    randomizedDelaySec = "30min";
    flags = [ "--refresh" ];
  };
  systemd.services.nixos-upgrade.environment = lib.mkIf (config.networking.fw-proxy.enable) config.networking.fw-proxy.environment;

  services.scheduled-reboot = {
    enable = true;
    # scheduled reboot before auto upgrade
    calendar = "03:00";
  };
}
