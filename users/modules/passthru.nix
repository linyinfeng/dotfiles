{ lib, ... }:
{
  options.passthru = lib.mkOption {
    type = with lib.types; attrsOf anything;
  };
}
