{
  config,
  lib,
  ...
}: {
  options = {
    routingTables = lib.mkOption {
      type = with lib.types; attrsOf int;
      default = {};
    };
    routingPolicyPriorities = lib.mkOption {
      type = with lib.types; attrsOf int;
      default = {};
    };
  };

  config = {
    assertions = [
      {
        assertion = let
          vals = lib.attrValues config.routingTables;
          noCollision = l: lib.length (lib.unique l) == lib.length l;
        in
          noCollision vals;
        message = "routing table id collision";
      }
      # routingPolicyPriorities collision is ok
    ];

    routingTables = {
      mesh-dn42 = 200;
      bgp-dn42 = 201;
      peer-dn42 = 202;

      as198764 = 210;
      as198764-catch = 211;

      fw-proxy = 854;
    };

    routingPolicyPriorities = {
      mesh-dn42 = 24210;
      peer-dn42 = 24220;
      bgp-dn42 = 24230;

      as198764 = 25000;
      as198764-catch = 25010;

      fw-proxy = 26000;
    };
  };
}
