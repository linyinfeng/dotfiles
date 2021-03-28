{ config, lib, ... }:

let
  cfg = config.home.global-persistence;
  home = "${config.home.homeDirectory}";
  persist = "${config.passthrough.systemConfig.environment.global-persistence.root}";
  persistHome = "${persist}${home}";
  sysCfg = config.passthrough.systemConfig.environment.global-persistence;
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
      type = types.str;
      default = false;
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
  };

  config = {
    home.global-persistence = {
      root = persistHome;
      directories = sysCfg.user.directories;
      files = sysCfg.user.files;
    };

    home.persistence = mkIf (sysCfg.enable && cfg.enable) {
      "${cfg.root}" = {
        directories = cfg.directories;
        files = cfg.files;
        allowOther = true;
      };
    };
  };
}
