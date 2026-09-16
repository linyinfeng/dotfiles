{
  lib,
  osConfig,
  config,
  ...
}:
let
  cfg = config.home.env.proxy;
  enabled = cfg.enable && cfg.mixedPort != null && osConfig.programs.dconf.enable;
  proxy = {
    host = "localhost";
    port = cfg.mixedPort;
  };
in
{
  dconf.settings = lib.mkIf enabled {
    "system/proxy" = {
      mode = "manual";
      use-same-proxy = true;
    };
    "system/proxy/http" = proxy;
    "system/proxy/https" = proxy;
    "system/proxy/socks" = proxy;
  };
}
