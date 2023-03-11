{...}: {
  perSystem = {pkgs, ...}: let
    secretExtractor = pkgs.callPackage ./extractor/secrets.nix {};
    dataExtractor = pkgs.callPackage ./extractor/data.nix {};
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
        '';
      }
      {
        category = "infrastructure";
        name = "terraform-wrapper";
        help = pkgs.terraform.meta.description;
        command = ''
          set -e

          export PATH=${pkgs.sops}/bin:$PATH
          export PATH=${pkgs.terraform}/bin:$PATH
          export PATH=${pkgs.zerotierone}/bin:$PATH
          export PATH=${pkgs.minio-client}/bin:$PATH
          export PATH=${pkgs.syncthing}/bin:$PATH
          export PATH=${pkgs.jq}/bin:$PATH
          export PATH=${pkgs.openssl}/bin:$PATH
          export PATH=${pkgs.ruby}/bin:$PATH

          encrypted_state_file="$PRJ_ROOT/secrets/terraform.tfstate"
          unencrypted_state_file="$PRJ_ROOT/terraform/terraform.tfstate"
          echo "decrypt terraform state to '$unencrypted_state_file'..." >&2
          sops --input-type json --output-type json \
            --decrypt "$encrypted_state_file" > "$unencrypted_state_file"

          function cleanup {
            cd $PRJ_ROOT
            if [ -n "$(cat "$unencrypted_state_file")" ]; then
              echo "encrypt terraform state to '$encrypted_state_file'..." >&2
              set +e
              EDITOR="cp \"$unencrypted_state_file\"" \
                sops --input-type json --output-type json \
                "$encrypted_state_file"
              encrypt_status="$?"
              set -e
              rm "$unencrypted_state_file"
              if [ "$encrypt_status" -ne 0 -a "$encrypt_status" -ne 200 ]; then
                echo "failed to encrypt, exiting"
                exit 1
              fi
            fi
          }
          trap cleanup EXIT

          cd $PRJ_ROOT/terraform
          terraform "$@"
        '';
      }

      {
        category = "infrastructure";
        name = "terraform-update-outputs";
        help = "update terraform outputs";
        command = ''
          set -e

          export PATH=${pkgs.sops}/bin:$PATH

          encrypted_output_file="$PRJ_ROOT/secrets/terraform-outputs.yaml"
          unencrypted_output_file="$PRJ_ROOT/secrets/terraform-outputs.plain.yaml"
          terraform-wrapper output --json > "$unencrypted_output_file"
          set +e
          EDITOR="cp \"$unencrypted_output_file\"" sops "$encrypted_output_file"
          encrypt_status="$?"
          set -e
          rm "$unencrypted_output_file"
          if [ "$encrypt_status" -ne 0 -a "$encrypt_status" -ne 200 ]; then
            echo "failed to encrypt, exiting"
            exit 1
          fi
        '';
      }

      {
        category = "infrastructure";
        name = "terraform-outputs-extract-secrets";
        help = "extract secrets from terraform outputs";
        package = secretExtractor;
      }

      {
        category = "infrastructure";
        name = "terraform-outputs-extract-data";
        help = "extract data from terraform outputs";
        package = dataExtractor;
      }

      {
        category = "infrastructure";
        name = "terraform-init";
        help = "upgrade terraform providers";
        command = ''
          set -e

          cd $PRJ_ROOT/terraform
          ${pkgs.terraform}/bin/terraform init "$@"
        '';
      }
    ];
  };
}
