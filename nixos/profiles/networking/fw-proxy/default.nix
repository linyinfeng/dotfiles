{
  config,
  lib,
  ...
}: let
  cfg = config.networking.fw-proxy;
  mixinCfg = cfg.mixinConfig;
  inherit (config.networking) hostName;
in {
  networking.fw-proxy = {
    enable = true;
    tproxy = {
      enable = lib.mkDefault true;
      slice = "tproxy";
      bypassSlice = "bypasstproxy";
      routingTable = config.routingTables.fw-proxy;
      rulePriority = config.routingPolicyPriorities.fw-proxy;
    };
    mixinConfig = {
      ipv6 = true;
      dns = {
        enable = true;
        listen = "[::]:${toString config.ports.proxy-dns}";
        ipv6 = true;
        default-nameserver = [
          "223.5.5.5"
          "223.6.6.6"
          "[2400:3200::1]:53"
          "[2400:3200:baba::1]:53"
        ];
        nameserver = [
          "https://101.6.6.6:8443/dns-query"
          "https://dns.alidns.com/dns-query"
        ];
        fallback = [
          "https://1.1.1.1/dns-query"
          "https://dns.google/dns-query"
        ];
        failback-filter = {
          geoio = true;
          geoip-code = "CN";
        };
      };
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
