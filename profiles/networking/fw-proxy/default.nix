{ config, lib, ... }:

let
  cfg = config.networking.fw-proxy;
in
{
  networking.fw-proxy.enable = true;
  systemd.services.nix-daemon.environment =
    lib.mkIf (!config.networking.fw-proxy.tun.enable) cfg.environment;
}
