{
  profiles,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.frp-client;
  settingsFormat = pkgs.formats.toml { };
  commonConfig = serverSettings: {
    inherit (cfg) enable;
    role = "client";
    settings =
      serverSettings
      // {
        transport.protocol = "wss";
        auth.token = "{{ .Envs.FRP_TOKEN }}";
      }
      // cfg.settings;
    inherit (cfg) extraConfig;
    environmentFiles = [ config.sops.templates."frp-token-env".path ];
  };
in
{
  imports = [
    profiles.services.frp-token
  ];
  options.services.frp-client = {
    enable = lib.mkEnableOption "frp-client";
    settings = lib.mkOption {
      inherit (settingsFormat) type;
    };
    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
    };
  };
  config = {
    services.frp.instances = {
      "nuc" = commonConfig {
        serverAddr = "frp-nuc.li7g.com";
        serverPort = 8443;
      };
      "mtl0" = commonConfig {
        serverAddr = "frp-mtl0.li7g.com";
        serverPort = 443;
      };
    };
  };
}
