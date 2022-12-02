{ config, lib, ... }:

let
  cfg = config.networking.fw-proxy;
in
{
  networking.fw-proxy = {
    enable = true;
    tproxy = {
      enable = true;
      cgroup = "tproxy";
    };
    mixinConfig = {
      port = 7890;
      socks-port = 7891;
      mixed-port = 8899;
      tproxy-port = 8900;
      log-level = "info";
      external-controller = "127.0.0.1:9090";
    };
  };

  networking.fw-proxy.auto-update = {
    enable = true;
    service = "main";
  };

  systemd.services.nix-daemon.environment = cfg.environment;
}
