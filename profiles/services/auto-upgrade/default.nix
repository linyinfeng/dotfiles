{ config, lib, ... }:

let
  cacheMachine = "nuc";
in
{
  system.autoUpgrade = {
    enable = true;
    flake = "github:linyinfeng/dotfiles/tested";
    allowReboot = true;
    dates = if config.networking.hostName == cacheMachine then "05:00" else "04:00";
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
