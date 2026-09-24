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

    systemdPackage = mkOption {
      type = with types; nullOr package;
      default = if pkgs.stdenv.hostPlatform.isLinux then pkgs.systemd else null;
      description = "The systemd package of the system.";
    };

    hostName = mkOption {
      type = types.str;
      default = "localhost";
      description = "Name of the machine.";
    };

    hosts = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = "Names of the hosts in this cluster.";
    };

    sshPort = mkOption {
      type = types.port;
      default = 22;
      description = "Port the hosts listen on for ssh.";
    };

    inputMethod = mkOption {
      type =
        with types;
        nullOr (enum [
          "fcitx5"
          "ibus"
        ]);
      default = null;
      description = "Input method the system provides, if any.";
    };

    rimeDataPkgs = mkOption {
      type = with types; listOf package;
      default = [ ];
      description = "Packages providing the rime data.";
    };

    secretPaths = mkOption {
      type = with types; attrsOf str;
      default = { };
      description = "Paths of secrets the system provides.";
    };
  };
}
