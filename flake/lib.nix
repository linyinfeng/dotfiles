{ config, lib, ... }:
{
  options.flake.libs = lib.mkOption {
    type = with lib.types; attrsOf unspecified;
  };
  config.flake.lib = config.flake.libs;
}
