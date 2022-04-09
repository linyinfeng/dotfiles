{ lib, ... }:

{
  options.hosts.nuc = {
    listens = lib.mkOption {
      type = with lib.types; listOf anything;
      default = [
        { addr = "[::]"; port = 80; }
        { addr = "[::]"; port = 443; ssl = true; }
        { addr = "[::]"; port = 8443; ssl = true; }
        { addr = "0.0.0.0"; port = 80; }
        { addr = "0.0.0.0"; port = 443; ssl = true; }
        { addr = "0.0.0.0"; port = 8443; ssl = true; }
      ];
    };
    ports = {
      grafana = lib.mkOption {
        type = lib.types.port;
        default = 3001;
      };
      hydra = lib.mkOption {
        type = lib.types.port;
        default = 3002;
      };
      nixServe = lib.mkOption {
        type = lib.types.port;
        default = 3003;
      };
      influxdb = lib.mkOption {
        type = lib.types.port;
        default = 3004;
      };
      loki = lib.mkOption {
        type = lib.types.port;
        default = 3005;
      };
      vaultwarden = {
        http = lib.mkOption {
          type = lib.types.port;
          default = 3006;
        };
        websocket = lib.mkOption {
          type = lib.types.port;
          default = 3007;
        };
      };
      matrix = {
        http = lib.mkOption {
          type = lib.types.port;
          default = 3008;
        };
      };
    };
  };
}
