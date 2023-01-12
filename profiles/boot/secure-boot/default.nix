{ config, lib, ... }:

{
  boot.lanzaboote = {
    enable = true;
    publicKeyFile = "/sbkeys/generated/db.crt";
    privateKeyFile = "/sbkeys/generated/db.key";
  };

  boot.kernelParams = [
    "lockdown=integrity"
  ];
  boot.kernelPatches = [
    # this patch makes the linux kernel unreproducible
    {
      name = "lockdown";
      patch = null;
      extraConfig = ''
        MODULE_SIG y
        SECURITY_LOCKDOWN_LSM y
      '';
    }
  ];
  assertions = [
    {
      assertion = lib.length config.boot.extraModulePackages == 0;
      message = "out-of-tree and unsigned kernel module not supported";
    }
  ];
}
