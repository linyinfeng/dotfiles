{ config, lib, ... }:

let
  cfg = config.home.global-persistence;
  home = "${config.home.homeDirectory}";
  sysCfg = config.passthrough.systemConfig.environment.global-persistence;
  persist = "${sysCfg.root}";
  persistHome = "${persist}${home}";
in

with lib;
{
  options.home.global-persistence = {
    enable = lib.mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable global home persistence storage.
      '';
    };

    root = lib.mkOption {
      type = with types; nullOr str;
      default = null;
      description = ''
        Root of home global persistence.
      '';
    };

    directories = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = ''
        A list of directories in your home directory that you want to link to persistent storage.
      '';
    };

    files = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = ''
        A list of files in your home directory you want to link to persistent storage.
      '';
    };

    enabled = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Is global home persistence storage enabled.
      '';
    };
  };

  config = mkIf (config.passthrough.systemConfig != null && sysCfg.enable) {
    home.global-persistence = {
      root = persistHome;
      directories = sysCfg.user.directories;
      files = sysCfg.user.files;
      enabled = cfg.enable;
    };

    home.persistence = mkIf (cfg.enabled) {
      "${cfg.root}" = {
        directories = cfg.directories;
        files = cfg.files;
        allowOther = true;
      };
    };
  };
}
