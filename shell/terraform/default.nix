{ pkgs, ... }:

let
  secretExtractor = pkgs.callPackage ./extractor/secrets.nix { };
  dataExtractor = pkgs.callPackage ./extractor/data.nix { };
in
{
  commands = [
    {
      category = "infrastructure";
      name = "terraform-wrapper";
      help = pkgs.terraform.meta.description;
      command = ''
        set -e

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
        ${pkgs.terraform}/bin/terraform "$@"
      '';
    }

    {
      category = "infrastructure";
      name = "terraform-update-outputs";
      help = "update terraform outputs";
      command = ''
        set -e

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

    {
      category = "infrastructure";
      name = "terraform-fmt";
      help = "format terraform files";
      command = ''
        set -e

        cd $PRJ_ROOT/terraform
        ${pkgs.terraform}/bin/terraform fmt --recursive "$@"
      '';
    }
  ];
}
