{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.lib.self) data;
  pkiBundle = pkgs.runCommand "secureboot-pki-bundle" { } ''
    mkdir "$out"
    ln --symbolic "${pkgs.writeText "GUID" data.secure_boot_signature_owner_guid}" "$out/GUID"
    mkdir --parents "$out/keys/"{PK,KEK,db,custom}
    ln --symbolic "${config.sops.secrets."secure_boot_pk_private_key_pkcs8".path}" "$out/keys/PK/PK.key"
    ln --symbolic "${pkgs.writeText "PK.pem" data.secure_boot_pk_cert_pem}" "$out/keys/PK/PK.pem"
    ln --symbolic "${
      config.sops.secrets."secure_boot_kek_private_key_pkcs8".path
    }" "$out/keys/KEK/KEK.key"
    ln --symbolic "${pkgs.writeText "KEK.pem" data.secure_boot_kek_cert_pem}" "$out/keys/KEK/KEK.pem"
    ln --symbolic "${config.sops.secrets."secure_boot_db_private_key_pkcs8".path}" "$out/keys/db/db.key"
    ln --symbolic "${pkgs.writeText "db.pem" data.secure_boot_db_cert_pem}" "$out/keys/db/db.pem"
    ln --symbolic "${
      aggregateCustomCerts "KEK" [
        # microsoft
        "${pkgs.nur.repos.linyinfeng.sources.secureboot_objects.src}/PreSignedObjects/KEK/Certificates"
      ]
    }" "$out/keys/custom/KEK"
    ln --symbolic "${
      aggregateCustomCerts "db" [
        # microsoft
        "${pkgs.nur.repos.linyinfeng.sources.secureboot_objects.src}/PreSignedObjects/DB/Certificates"
      ]
    }" "$out/keys/custom/db"
  '';
  aggregateCustomCerts =
    type: paths:
    let
      symlinks = pkgs.buildEnv {
        name = "secureboot-custom-${type}-symlinks";
        inherit paths;
      };
    in
    # ensure certificates are regular files (required by sbctl)
    pkgs.runCommand "secureboot-custom-${type}" { } ''
      cp --recursive --dereference "${symlinks}" "$out"
    '';
in
{
  options = {
    boot.secureBoot = {
      publicKeyFile = lib.mkOption {
        type = lib.types.path;
        default = pkgs.writeText "module-signing.crt" data.secure_boot_db_cert_pem;
      };
      privateKeyFile = lib.mkOption {
        type = lib.types.path;
        default = config.sops.secrets."secure_boot_db_private_key".path;
      };
    };
    boot.kernelModuleSigning = {
      enable = lib.mkEnableOption "kernel module signing";
      hash = lib.mkOption {
        type = lib.types.enum [
          "SHA1"
          "SHA224"
          "SHA256"
          "SHA384"
          "SHA512"
        ];
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
          name = "sign-module";
          text =
            let
              inherit (config.boot.kernelPackages) kernel;
            in
            ''
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
        settings = {
          reboot-for-bitlocker = true;
        };
      };
      boot.kernelPatches = [
        {
          name = "uefi-keyring";
          patch = null;
          extraStructuredConfig = with lib.kernel; {
            INTEGRITY_MACHINE_KEYRING = yes;
            INTEGRITY_PLATFORM_KEYRING = yes;
            INTEGRITY_ASYMMETRIC_KEYS = yes;
            INTEGRITY_SIGNATURE = yes;
            SECONDARY_TRUSTED_KEYRING = yes;
            SYSTEM_BLACKLIST_KEYRING = yes;
            LOAD_UEFI_KEYS = yes;
          };
        }
      ];
    }
    # shim
    {
      boot.secureBoot.shim = {
        enable = true;
        loader = "systemd-boot${config.boot.secureBoot.shim.archSuffix}.efi";
        directory = "EFI/systemd";
        removable.enable = true;
        bootEntry = {
          install = true;
          label = "Linux Boot Manager";
        };
        mokManager.addEntry = true;
      };
      # install-shim after lzbt
      boot.lanzaboote.package = lib.mkForce (
        pkgs.writeShellApplication {
          name = "lzbt";
          runtimeInputs = [
            pkgs.lanzaboote.tool
            config.system.build.installShim
          ];
          text = ''
            lzbt "$@"
            install-shim
          '';
        }
      );
    }
    # sbctl
    {
      environment.systemPackages = with pkgs; [ sbctl ];
      systemd.tmpfiles.settings."80-sbctl" = {
        "/var/lib/sbctl" = {
          "C+" = {
            argument = "${pkiBundle}";
          };
        };
      };
      sops.secrets."secure_boot_pk_private_key_pkcs8".terraformOutput.enable = true;
      sops.secrets."secure_boot_kek_private_key_pkcs8".terraformOutput.enable = true;
      sops.secrets."secure_boot_db_private_key_pkcs8".terraformOutput.enable = true;
    }
    (lib.mkIf config.boot.kernelModuleSigning.enable {
      boot.kernelPatches = [
        # this patch makes the linux kernel unreproducible
        {
          _file = ./default.nix;
          name = "moduel-signing";
          patch = null;
          extraStructuredConfig = with lib.kernel; {
            MODULE_SIG = lib.mkForce yes;
            MODULE_SIG_SHA512 = yes;
            MODULE_SIG_HASH = freeform "sha512";
            MODULE_SIG_KEY = freeform config.boot.kernelModuleSigning.combined;
          };
        }
      ];
    })
    (lib.mkIf config.boot.kernelLockdown {
      boot.kernelParams = [ "lockdown=integrity" ];
      boot.kernelPatches = [
        {
          name = "lockdown";
          patch = null;
          extraStructuredConfig = with lib.kernel; {
            SECURITY_LOCKDOWN_LSM = lib.mkForce yes;
          };
        }
      ];
    })
  ];
}
