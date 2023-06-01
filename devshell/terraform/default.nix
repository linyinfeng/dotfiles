{...}: {
  perSystem = {pkgs, ...}: let
    common = pkgs.substituteAll {
      src = ./common.sh;
      isExecutable = true;
      inherit (pkgs.stdenvNoCC) shell;
    };

    encryptTo = pkgs.substituteAll {
      src = ./encrypt-to.sh;
      isExecutable = true;
      inherit common;
      inherit (pkgs.stdenvNoCC) shell;
      inherit (pkgs) sops;
    };

    terraformInit = pkgs.substituteAll {
      src = ./terraform-init.sh;
      isExecutable = true;
      inherit common;
      inherit (pkgs.stdenvNoCC) shell;
      inherit (pkgs) terraform;
    };

    terraformOutputsExtractData = pkgs.substituteAll {
      src = ./terraform-outputs-extract-data.sh;
      isExecutable = true;
      inherit common;
      inherit (pkgs.stdenvNoCC) shell;
      inherit (pkgs) yq-go sops;
    };

    terraformOutputsExtractSecrets = pkgs.substituteAll {
      src = ./terraform-outputs-extract-secrets.sh;
      isExecutable = true;
      inherit common encryptTo;
      inherit (pkgs.stdenvNoCC) shell;
      inherit (pkgs) yq-go sops fd;
    };

    terraformUpdateOutputs = pkgs.substituteAll {
      src = ./terraform-update-outputs.sh;
      isExecutable = true;
      inherit common encryptTo terraformWrapper;
      inherit (pkgs.stdenvNoCC) shell;
      inherit (pkgs) yq-go;
    };

    terraformWrapper = pkgs.substituteAll {
      src = ./terraform-wrapper.sh;
      isExecutable = true;
      inherit common encryptTo;
      inherit (pkgs.stdenvNoCC) shell;
      inherit (pkgs) sops terraform zerotierone minio-client syncthing jq openssl ruby yq-go;
    };
  in {
    devshells.default.commands = [
      {
        category = "infrastructure";
        name = "terraform-pipe";
        help = "initialize, apply, and update all terraform related output files";
        command = ''
          set -e

          terraform-init
          terraform-wrapper apply
          terraform-update-outputs
          terraform-outputs-extract-data
          terraform-outputs-extract-secrets
          nix fmt
        '';
      }
      {
        category = "infrastructure";
        name = "terraform-wrapper";
        help = pkgs.terraform.meta.description;
        command = ''
          ${terraformWrapper} "$@"
        '';
      }

      {
        category = "infrastructure";
        name = "terraform-update-outputs";
        help = "update terraform outputs";
        command = ''
          ${terraformUpdateOutputs} "$@"
        '';
      }

      {
        category = "infrastructure";
        name = "terraform-outputs-extract-secrets";
        help = "extract secrets from terraform outputs";
        command = ''
          ${terraformOutputsExtractSecrets} "$@"
        '';
      }

      {
        category = "infrastructure";
        name = "terraform-outputs-extract-data";
        help = "extract data from terraform outputs";
        command = ''
          ${terraformOutputsExtractData} "$@"
        '';
      }

      {
        category = "infrastructure";
        name = "terraform-init";
        help = "upgrade terraform providers";
        command = ''
          ${terraformInit} "$@"
        '';
      }

      {
        category = "infrastructure";
        name = "encrypt-to";
        help = "sops encrypt helper";
        command = ''
          ${encryptTo} "$@"
        '';
      }

      {
        package = pkgs.cf-terraforming;
        category = "infrastructure";
      }
    ];
  };
}
