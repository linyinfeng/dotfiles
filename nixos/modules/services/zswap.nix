{
  config,
  lib,
  ...
}:
let
  cfg = config.services.zswap;
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
    boot.kernel.sysfs = {
      module.zswap.parameters = {
        enabled = cfg.enable;
        inherit (cfg) compressor;
        max_pool_percent = cfg.maxPoolPercent;
        shrinker_enabled = cfg.shrinkerEnabled;
      };
    };
  };
}
