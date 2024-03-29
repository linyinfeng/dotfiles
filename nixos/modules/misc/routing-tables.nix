{ config, lib, ... }:
{
  options = {
    routingTables = lib.mkOption {
      type = with lib.types; attrsOf int;
      default = { };
    };
    routingPolicyPriorities = lib.mkOption {
      type = with lib.types; attrsOf int;
      default = { };
    };
  };

  config = {
    assertions = [
      {
        assertion =
          let
            vals = lib.attrValues config.routingTables;
            noCollision = l: lib.length (lib.unique l) == lib.length l;
          in
          noCollision vals;
        message = "routing table id collision";
      }
      # routingPolicyPriorities collision is ok
    ];

    routingTables = {
      mesh = 200;

      dn42-bgp = 300;

      fw-proxy = 854;
    };

    routingPolicyPriorities = {
      mesh = 24000;

      dn42-bgp = 24500;

      fw-proxy = 26000;
    };
  };
}
