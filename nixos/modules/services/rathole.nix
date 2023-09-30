{ config, lib, pkgs, ... }:

let
  cfg = config.services.rathole;
in
{
  options.services.rathole = {
    enable = lib.mkEnableOption "rathole";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.rathole;
      defaultText = "pkgs.rathole";
      description = ''
        Rathole package to use.
      '';
    };
    configFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Configuration file for rathole.
      '';
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.services.rathole = {
      serviceConfig = {
        ExecStart = ''${pkgs.rathole}/bin/rathole "$CREDENTIALS_DIRECTORY/rathole.toml"'';
        DynamicUser = true;
        Restart = "on-failure";
        LoadCredential = [
          "rathole.toml:${cfg.configFile}"
        ];
      };
      wantedBy = ["multi-user.service"];
    };
  };
}
