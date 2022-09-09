{ lib, ... }:

{
  options.hosts.rica = {
    ports = {
      pastebin = lib.mkOption {
        type = lib.types.port;
        default = 3000;
      };
      vaultwarden = {
        http = lib.mkOption {
          type = lib.types.port;
          default = 3001;
        };
        websocket = lib.mkOption {
          type = lib.types.port;
          default = 3002;
        };
      };
      matrix = {
        http = lib.mkOption {
          type = lib.types.port;
          default = 3003;
        };
      };
      influxdb = lib.mkOption {
        type = lib.types.port;
        default = 3004;
      };
      loki = lib.mkOption {
        type = lib.types.port;
        default = 3005;
      };
      grafana = lib.mkOption {
        type = lib.types.port;
        default = 3006;
      };
      alertmanager = lib.mkOption {
        type = lib.types.port;
        default = 3007;
      };
    };
  };
}
