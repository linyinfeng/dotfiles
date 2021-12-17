{ config, lib, pkgs, ... }:

let
  cfg = config.services.telegraf-influx;
in
{
  options.services.telegraf-influx = {
    enable = lib.mkEnableOption "telegraf server";

    package = lib.mkOption {
      type = lib.types.package;
      description = "Which telegraf derivation to use";
      default = pkgs.telegraf;
      defaultText = lib.literalExpression "pkgs.telegraf";
    };

    tokenFile = lib.mkOption {
      type = lib.types.str;
      description = "File contains INFLUX_TOKEN";
    };

    configUrl = lib.mkOption {
      type = lib.types.str;
      description = "Configuration URL";
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.services.telegraf-influx = {
      description = "Telegraf Agent";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      script = ''
        export INFLUX_TOKEN=$(cat "$CREDENTIALS_DIRECTORY/token")

        ${cfg.package}/bin/telegraf --config "${cfg.configUrl}"
      '';
      serviceConfig = {
        ExecReload="${pkgs.coreutils}/bin/kill -HUP $MAINPID";

        RuntimeDirectory = "telegraf";
        LoadCredential = [
          "token:${cfg.tokenFile}"
        ];

        User = "telegraf";
        Group = "telegraf";

        Restart = "on-failure";
        # for ping probes
        AmbientCapabilities = [ "CAP_NET_RAW" ];
      };
      path = [
        pkgs.lm_sensors
      ];
    };

    users.users.telegraf = {
      uid = config.ids.uids.telegraf;
      group = "telegraf";
      description = "telegraf daemon user";
    };

    users.groups.telegraf = {};
  };
}
