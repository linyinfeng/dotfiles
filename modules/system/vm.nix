{ config, lib, options, ... }:

let
  isVm = config.fileSystems ? "/tmp/xchg" && config.fileSystems."/tmp/xchg".fsType == "9p";
in
{
  options.system.is-vm = lib.mkOption {
    type = lib.types.bool;
    default = config.system.is-vm-test || isVm;
    readOnly = true;
    description = ''
      Wheather the configuration is built in a vm test environment.
    '';
  };

  config = lib.mkIf config.system.is-vm {
    # increase 9p msize
    virtualisation =
      if options.virtualisation ? msize then {
        msize = 256 * 1024;
      } else { };
  };
}
