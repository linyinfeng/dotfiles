{ config, lib, ... }:

{
  options.ports = lib.mkOption {
    type = with lib.types; attrsOf port;
    default = { };
  };

  config = {
    assertions = [
      {
        assertion =
          let
            vals = lib.attrValues config.ports;
            noCollision = l: lib.length (lib.unique l) == lib.length l;
          in
          noCollision vals;
        message = "ports collision";
      }
    ];

    ports = {
      smtp-tls = 465;
      smtp-starttls = 587;
      pastebin = 3000;
      vaultwarden-http = 3010;
      vaultwarden-websocket = 3011;
      influxdb = 3020;
      loki = 3030;
      grafana = 3040;
      alertmanager = 3050;
      seafile-file-server = 3060;
      hydra = 3070;
      nix-serve = 3080;
      matrix = 3090;
      mautrix-telegram-appservice = 3100;
      minio = 3110;
      minio-console = 3111;
      minecraft = 25565;
      minecraft-rcon = 25566;
      minecraft-map = 25567;
    };
  };
}
