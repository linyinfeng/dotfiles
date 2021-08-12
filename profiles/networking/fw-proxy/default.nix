{ config, ... }:

let
  cfg = config.networking.fw-proxy;
in
{
  networking.fw-proxy.enable = true;
  systemd.services.nix-daemon.environment = cfg.environment;
}
