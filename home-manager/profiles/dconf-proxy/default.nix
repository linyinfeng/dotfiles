{
  lib,
  osConfig,
  ...
}: let
  proxy = {
    host = "localhost";
    port = osConfig.networking.fw-proxy.mixinConfig.mixed-port;
  };
in {
  dconf.settings = lib.mkIf (osConfig.networking.fw-proxy.enable) {
    "system/proxy" = {
      mode = "manual";
      use-same-proxy = true;
    };
    "system/proxy/http" = proxy;
    "system/proxy/https" = proxy;
    "system/proxy/socks" = proxy;
  };
}