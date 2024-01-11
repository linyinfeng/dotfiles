{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    boot.secureBoot = {
      publicKeyFile = lib.mkOption {
        type = lib.types.path;
        default = pkgs.writeText "module-signing.crt" config.lib.self.data.secure_boot_db_cert_pem;
      };
      privateKeyFile = lib.mkOption {
        type = lib.types.path;
        default = config.sops.secrets."secure_boot_db_private_key".path;
      };
    };
    boot.kernelModuleSigning = {
      enable = lib.mkEnableOption "kernel module signing";
      hash = lib.mkOption {
        type = lib.types.enum ["SHA1" "SHA224" "SHA256" "SHA384" "SHA512"];
        default = "SHA512";
      };
      certificate = lib.mkOption {
        type = lib.types.path;
        # just the same as the database key
        default = config.boot.secureBoot.publicKeyFile;
      };
      key = lib.mkOption {
        type = lib.types.path;
        default = config.boot.secureBoot.privateKeyFile;
      };
      # defined in profiles/nix/hydra-builder-server
      # kernel and modules must be built on thess servers
      combined = lib.mkOption {
        type = lib.types.path;
        default = config.sops.templates."linux-module-signing-key.pem".path;
      };
      signModule = lib.mkOption {
        type = lib.types.path;
        default = pkgs.writeShellApplication {
          name = "signModule";
          text = let
            inherit (config.boot.kernelPackages) kernel;
          in ''
            echo "Signing kernel module '$1'..."
            "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build/scripts/sign-file" \
              "${config.boot.kernelModuleSigning.hash}" \
              "${config.boot.kernelModuleSigning.key}" \
              "${config.boot.kernelModuleSigning.certificate}" \
              "$@"
          '';
        };
      };
    };
    boot.kernelLockdown = lib.mkEnableOption "kernel lockdown";
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = config.boot.kernelLockdown -> config.boot.kernelModuleSigning.enable;
          message = "boot.kernelLockdown requires boot.kernelModuleSigning.enable";
        }
      ];
    }
    {
      boot.lanzaboote = {
        enable = true;
        inherit (config.boot.secureBoot) publicKeyFile privateKeyFile;
      };
      boot.kernelPatches = [
        {
          name = "uefi-keyring";
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
    (lib.mkIf config.boot.kernelModuleSigning.enable {
      boot.kernelPatches = [
        # this patch makes the linux kernel unreproducible
        {
          name = "moduel-signing";
          patch = null;
          extraConfig = ''
            MODULE_SIG y
            MODULE_SIG_SHA512 y
            MODULE_SIG_HASH sha512
            MODULE_SIG_KEY ${config.boot.kernelModuleSigning.combined}
          '';
        }
      ];
    })
    (lib.mkIf config.boot.kernelLockdown {
      boot.kernelParams = [
        "lockdown=integrity"
      ];
      boot.kernelPatches = [
        {
          name = "lockdown";
          patch = null;
          extraConfig = ''
            SECURITY_LOCKDOWN_LSM y
          '';
        }
      ];
    })
  ];
}
