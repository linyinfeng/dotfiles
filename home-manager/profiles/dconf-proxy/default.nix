{ lib, osConfig, ... }:
let
  proxy = {
    host = "localhost";
    port = osConfig.networking.fw-proxy.ports.mixed;
  };
in
{
  dconf.settings = lib.mkIf (osConfig.networking.fw-proxy.enable && osConfig.programs.dconf.enable) {
    "system/proxy" = {
      mode = "manual";
      use-same-proxy = true;
    };
    "system/proxy/http" = proxy;
    "system/proxy/https" = proxy;
    "system/proxy/socks" = proxy;
  };
}
