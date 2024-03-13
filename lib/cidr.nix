{lib}: {
  parse = cidr: let
    match = lib.strings.match "(.*)/([0-9]+)" cidr;
  in {
    address = lib.elemAt match 0;
    prefixLength = lib.toInt (lib.elemAt match 1);
  };

  module = {...}: {
    _file = ./cidr.nix;
    options = {
      address = lib.mkOption {
        type = lib.types.str;
      };
      prefixLength = lib.mkOption {
        type = lib.types.int;
      };
    };
  };
}
