systemConfig:
{ config, lib, ... }:

{
  options.passthrough.systemConfig = lib.mkOption {
    type = lib.types.attrs;
    description = ''
      Full system configuration.
    '';
  };

  config = {
    passthrough = { inherit systemConfig; };
  };
}
