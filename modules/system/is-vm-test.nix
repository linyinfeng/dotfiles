{ config, lib, ... }:

let
  isVmTest = config.system.nixos.revision == "constant-nixos-revision";
in
{
  options.system.is-vm-test = lib.mkOption {
    type = lib.types.bool;
    default = isVmTest;
    readOnly = true;
    description = ''
      Wheather the configuration is built in a vm test environment.
    '';
  };
}
