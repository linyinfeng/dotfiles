{ config, lib, ... }:
{
  services.fwupd.enable = true;
  systemd.services.fwupd-refresh = {
    environment = lib.mkIf config.networking.fw-proxy.enable config.networking.fw-proxy.environment;
  };
}
