{ config, lib, ... }:

{
  system.autoUpgrade = {
    enable = true;
    flake = "github:linyinfeng/dotfiles/tested";
    allowReboot = true;
  };
  systemd.services.nixos-upgrade.environment =
    lib.mkIf (config.networking.fw-proxy.enable)
      config.networking.fw-proxy.environment;
}
