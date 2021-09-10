{ config, lib, ... }:

let
  cfg = config.networking.fw-proxy;
in
{
  networking.fw-proxy.enable = true;
  systemd.services.nix-daemon.environment = cfg.environment;

  nix.binaryCaches = [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" ];
}
