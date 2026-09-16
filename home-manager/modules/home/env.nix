{ lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  options.home.env = {
    proxy = {
      enable = mkEnableOption "the system proxy environment";

      environment = mkOption {
        type = with types; attrsOf str;
        default = { };
        description = "Proxy environment as attribute set.";
      };

      stringEnvironment = mkOption {
        type = with types; listOf str;
        default = [ ];
        description = "Proxy environment as KEY=value strings.";
      };

      mixedPort = mkOption {
        type = with types; nullOr port;
        default = null;
        description = "Mixed port of the system proxy.";
      };
    };

    dconf = mkOption {
      type = types.bool;
      default = false;
      description = "Whether the system provides dconf.";
    };

    types = mkOption {
      type =
        with types;
        listOf (enum [
          "server"
          "workstation"
          "phone"
        ]);
      default = [ ];
      description = "System types.";
    };

    desktopManagers = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = "Desktop managers the system provides.";
    };

    systemdPackage = mkOption {
      type = with types; nullOr package;
      default = if pkgs.stdenv.hostPlatform.isLinux then pkgs.systemd else null;
      description = "The systemd package of the system.";
    };
  };
}
