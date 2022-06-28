{ config, lib, osConfig, ... }:

let
  cfg = config.home.global-persistence;
  sysCfg = osConfig.environment.global-persistence;
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

    home = mkOption {
      type = types.str;
      description = ''
        Home directory.
      '';
    };

    directories = mkOption {
      type = with types; listOf anything;
      default = [ ];
      description = ''
        A list of directories in your home directory that you want to link to persistent storage.
      '';
    };

    files = mkOption {
      type = with types; listOf anything;
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

  config = mkIf sysCfg.enable {
    home.global-persistence = {
      directories = sysCfg.user.directories;
      files = sysCfg.user.files;
      enabled = cfg.enable;
    };
  };
}
