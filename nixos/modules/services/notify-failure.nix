{
  config,
  lib,
  ...
}: let
  cfg = config.services.notify-failure;
in
  with lib; {
    options.services.notify-failure = {
      enable =
        mkOption
        {
          type = types.bool;
          default = false;
          description = ''
            Whether to enable notify-failure service.
          '';
        };
      config =
        mkOption
        {
          type = types.attrs;
          description = ''
            Service config for "notify-failure@.service".
          '';
        };
      services =
        mkOption
        {
          type = with types; listOf str;
          default = [];
          description = ''
            Services to be monitored.
          '';
        };
    };
    config = mkIf (cfg.enable) (mkMerge [
      {
        systemd.services."notify-failure@" = mkMerge [
          {
            description = "Failure notification for %i";
            scriptArgs = ''"%i" "Hostname: %H" "Machine ID: %m" "Boot ID: %b"'';
          }
          cfg.config
        ];
      }
      {
        systemd.services = lib.listToAttrs (map
          (service:
            lib.nameValuePair service {
              onFailure = ["notify-failure@%n.service"];
            })
          cfg.services);
      }
    ]);
  }
