{ config, lib, ... }:
let
  inherit (config.networking) hostName;
in
{
  system.autoUpgrade = {
    enable = true;
    flake = "github:linyinfeng/dotfiles/nixos-tested-${hostName}";
    allowReboot = true;
    # Reboot only around the upgrade time. The upgrade timer also runs when the
    # machine was suspended over 04:00 and only wakes up later; a reboot then
    # would hit the user right after resuming, so anything outside the window
    # just skips the reboot.
    rebootWindow = {
      lower = "03:00";
      upper = "05:00";
    };
    dates = "04:00";
    randomizedDelaySec = "30min";
    flags = [ "--refresh" ];
  };
  systemd.services.nixos-upgrade.environment = lib.mkIf config.networking.fw-proxy.enable config.networking.fw-proxy.environment;
}
