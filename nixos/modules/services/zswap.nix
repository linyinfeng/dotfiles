{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.zswap;

  zswapSetup = pkgs.writeShellApplication {
    name = "zswap-setup";
    text = ''
      action="$1"

      case "$action" in
      up)
        echo ${cfg.compressor}              | tee /sys/module/zswap/parameters/compressor
        echo ${toString cfg.maxPoolPercent} | tee /sys/module/zswap/parameters/max_pool_percent
        echo ${cfg.shrinkerEnabled} | tee /sys/module/zswap/parameters/shrinker_enabled

        echo Y | tee /sys/module/zswap/parameters/enabled
        grep -r . /sys/module/zswap/parameters
        ;;

      down)
        echo N | tee /sys/module/zswap/parameters/enabled
        grep -r . /sys/module/zswap/parameters
        ;;

      *)
        grep -r . /sys/module/zswap/parameters
        ;;

      esac
    '';
  };
in
{
  options.services.zswap = {
    enable = lib.mkEnableOption "zswap";
    compressor = lib.mkOption {
      type = with lib.types; str;
      default = "zstd";
    };
    maxPoolPercent = lib.mkOption {
      type = with lib.types; int;
      default = 20;
    };
    shrinkerEnabled = lib.mkOption {
      type =
        with lib.types;
        enum [
          "N"
          "Y"
        ];
      default = "Y";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !(cfg.enable && config.zramSwap.enable);
        message = "zswap and zram based swap should not be enabled at the same time";
      }
    ];
    systemd.services.zswap = {
      serviceConfig = {
        ExecStart = "${lib.getExe zswapSetup} up";
        ExecStop = "${lib.getExe zswapSetup} down";
        Type = "oneshot";
        RemainAfterExit = true;
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
