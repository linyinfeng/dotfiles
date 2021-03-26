{ config, lib, ... }:

let
  cfg = config.home.global-persistence;
  home = "${config.home.homeDirectory}";
  persist = "${config.passthrough.systemConfig.environment.global-persistence.root}";
  persistHome = "${persist}${home}";
  systemWiseEnabled = config.passthrough.systemConfig.environment.global-persistence.enable;
in

with lib;
{
  options.home.global-persistence = {
    enable = lib.mkOption {
      type = types.bool;
      default = systemWiseEnabled;
      description = ''
        Whether to enable global home persistence storage.
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
    home.persistence = mkIf (cfg.enable) {
      "${persistHome}" = {
        directories = cfg.directories;
        files = cfg.files;
        allowOther = true;
      };
    };
  };
}
