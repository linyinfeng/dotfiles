{
  config,
  lib,
  ...
}: let
  cfg = config.networking.fw-proxy;
  inherit (config.networking) hostName;
in {
  networking.fw-proxy = {
    enable = true;
    tproxy = {
      enable = lib.mkDefault true;
      cgroup = "tproxy.slice";
      routingTable = config.routingTables.fw-proxy;
      rulePriority = config.routingPolicyPriorities.fw-proxy;
    };
    mixinConfig = {
      port = config.ports.proxy-http;
      socks-port = config.ports.proxy-socks;
      mixed-port = config.ports.proxy-mixed;
      tproxy-port = config.ports.proxy-tproxy;
      log-level = "info";
      external-controller = "127.0.0.1:${toString config.ports.clash-controller}";
    };
    externalController = {
      expose = true;
      virtualHost = "${hostName}.*";
      location = "/clash/";
      secretFile = config.sops.secrets."fw_proxy_external_controller_secret".path;
    };
  };

  sops.secrets."fw_proxy_external_controller_secret" = {
    sopsFile = config.sops-file.get "terraform/common.yaml";
    restartUnits = ["clash-auto-update.service"];
  };

  networking.fw-proxy.auto-update = {
    enable = true;
    service = "main";
  };

  systemd.services.nix-daemon.environment = cfg.environment;
}
