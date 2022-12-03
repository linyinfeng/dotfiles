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
      port = config.ports.proxy-http;
      socks-port = config.ports.proxy-socks;
      mixed-port = config.ports.proxy-mixed;
      tproxy-port = config.ports.proxy-tproxy;
      log-level = "info";
      external-controller = "127.0.0.1:${toString config.ports.clash-controller}";
    };
  };

  networking.fw-proxy.auto-update = {
    enable = true;
    service = "main";
  };

  systemd.services.nix-daemon.environment = cfg.environment;
}
