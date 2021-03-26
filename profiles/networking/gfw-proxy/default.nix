{ config, ... }:

let
  cfg = config.networking.gfw-proxy;
in
{
  networking.gfw-proxy.enable = true;
  systemd.services.nix-daemon.environment = cfg.environment;
  systemd.services.docker.environment = cfg.environment;
  systemd.services.flatpak-system-helper.environment = cfg.environment;
}
