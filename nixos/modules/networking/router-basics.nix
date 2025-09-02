{ config, lib, ... }:
let
  cfg = config.networking.routerBasics;
in
{
  options.networking.routerBasics.enable = lib.mkEnableOption "router basics";
  config = lib.mkIf cfg.enable {
    boot.kernel.sysctl = {
      "net.ipv6.conf.default.forwarding" = 1;
      "net.ipv4.conf.default.forwarding" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
      "net.ipv4.conf.all.forwarding" = 1;
      # disable rp_filter
      "net.ipv4.conf.all.rp_filter" = 0;
      "net.ipv4.conf.default.rp_filter" = 0;
      "net.ipv4.conf.*.rp_filter" = 0;
    };
    networking.firewall.checkReversePath = false;
  };
}
