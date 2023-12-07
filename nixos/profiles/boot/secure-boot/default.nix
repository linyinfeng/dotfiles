{
  config,
  lib,
  ...
}: {
  options = {
    boot.kernelLockdown = lib.mkEnableOption "kernel lockdown";
  };

  config = lib.mkMerge [
    {
      boot.lanzaboote = {
        enable = true;
        publicKeyFile = "/sbkeys/generated/db.crt";
        privateKeyFile = "/sbkeys/generated/db.key";
      };
      boot.kernelPatches = [
        {
          name = "keyring";
          patch = null;
          extraConfig = ''
            INTEGRITY_MACHINE_KEYRING y
            INTEGRITY_PLATFORM_KEYRING y
            INTEGRITY_ASYMMETRIC_KEYS y
            INTEGRITY_SIGNATURE y
            SECONDARY_TRUSTED_KEYRING y
            SYSTEM_BLACKLIST_KEYRING y
            LOAD_UEFI_KEYS y
          '';
        }
      ];
    }
    (lib.mkIf config.boot.kernelLockdown {
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
      # assertions = [
      #   {
      #     assertion = lib.length config.boot.extraModulePackages == 0;
      #     message = "out-of-tree and unsigned kernel module not supported";
      #   }
      # ];
    })
  ];
}
