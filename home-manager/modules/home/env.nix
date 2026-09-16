{ lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  options.home.env.proxy = {
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
}
