{ pkgs, ... }:
let
  common = builtins.readFile ./common.sh;

  encryptTo = pkgs.writeShellApplication {
    name = "encrypt-to";
    runtimeInputs = with pkgs; [ sops ];
    text = ''
      ${common}

      plain_file="$1"
      target_file="$2"
      type="$3"
      IFS=" " read -r -a formatter <<<"$4"

      message "encryping '$plain_file' to '$target_file' (type: '$type', formatter: '''''${formatter[*]}')..."

      if [ -e "$target_file" ]; then
        tmp_dir=$(mktemp -t --directory encrypt.XXXXXXXXXX)
        target_plain="$tmp_dir/target_plain"
        target_plain_formatted="$tmp_dir/target_plain_formatted"
        plain_formatted="$tmp_dir/plain_formatted"

        function cleanup {
          rm -r "$tmp_dir"
        }
        trap cleanup EXIT

        sops --input-type "$type" --output-type "$type" \
          --decrypt "$target_file" >"$target_plain"

        "''${formatter[@]}" "$target_plain" >"$target_plain_formatted"
        "''${formatter[@]}" "$plain_file" >"$plain_formatted"

        if diff "$plain_formatted" "$target_plain_formatted" >/dev/null 2>&1; then
          message "same, skipping..."
          exit 0
        fi
      fi

      EDITOR="cp '$plain_file'" \
        sops --input-type "$type" --output-type "$type" "$target_file"
    '';
  };

  terraformInit = pkgs.writeShellApplication {
    name = "terraform-init";
    runtimeInputs = with pkgs; [ terraform ];
    text = ''
      terraform -chdir="$(realpath "$TERRAFORM_DIR")" init "$@"
    '';
  };

  terraformWrapper = pkgs.writeShellApplication {
    name = "terraform-wrapper";
    runtimeInputs = with pkgs; [
      sops
      terraform
      zerotierone
      minio-client
      syncthing
      libargon2
      jq
      openssl
      ruby
      yq-go
      efitools
      bind
      encryptTo
    ];
    text = ''
      ${common}

      encrypted="$SECRETS_DIR/terraform.tfstate"
      plain="$TERRAFORM_DIR/terraform.tfstate"

      message "decrypt terraform state to '$plain'..."
      sops --input-type json --output-type json \
        --decrypt "$encrypted" >"$plain"

      function cleanup {
        exit_code=$?

        set -e

        if [ -n "$(cat "$plain")" ]; then
          encrypt-to "$plain" "$encrypted" json "yq --prettyPrint"
        fi
        message "deleting terraform state '$plain'..."
        rm -f "$plain"* # remove plain and backup files

        message "terraform exit code: $exit_code"
        exit $exit_code
      }
      trap cleanup EXIT

      set +e
      terraform -chdir="$(realpath "$TERRAFORM_DIR")" "$@"
    '';
  };

  terraformUpdateOutputs = pkgs.writeShellApplication {
    name = "terraform-update-outputs";
    runtimeInputs = with pkgs; [
      encryptTo
      terraformWrapper
      yq-go
    ];
    text = ''
      ${common}

      tmp_dir=$(mktemp -t --directory encrypt.XXXXXXXXXX)
      function cleanup {
        rm -r "$tmp_dir"
      }
      trap cleanup EXIT

      plain_output="$tmp_dir/terraform-outputs.plain.yaml"

      terraform-wrapper output --json >"$plain_output"
      encrypt-to "$plain_output" "$SECRETS_DIR/terraform-outputs.yaml" yaml "yq --prettyPrint"
    '';
  };

  terraformOutputsExtractData = pkgs.writeShellApplication {
    name = "terraform-outputs-extract-data";
    runtimeInputs = with pkgs; [
      yq-go
      sops
    ];
    text = ''
      ${common}

      format="json"
      message "creating 'data.$format'..."
      sops exec-file "$SECRETS_DIR/terraform-outputs.yaml" \
        "yq eval --from-file \"$DATA_EXTRACT_DIR/template.yq\" {} --output-format $format" \
        >"$DATA_EXTRACT_DIR/data.$format"
    '';
  };
in
{
  devshells.default = {
    commands = [
      {
        category = "infrastructure";
        name = "terraform-pipe";
        help = "initialize, apply, and update all terraform related output files";
        command = ''
          set -e

          git -C "$SECRETS_DIR" pull
          function cleanup {
            git -C "$SECRETS_DIR" add --all
            git -C "$SECRETS_DIR" commit --message "Terraform apply"
            git -C "$SECRETS_DIR" push
          }
          trap cleanup EXIT

          terraform-init
          terraform-wrapper apply "$@"
          terraform-update-outputs
          terraform-outputs-extract-data

          extract-secrets

          nix fmt
        '';
      }

      {
        category = "terraform";
        package = pkgs.terraform;
      }

      {
        category = "infrastructure";
        package = terraformWrapper;
      }

      {
        category = "infrastructure";
        package = terraformUpdateOutputs;
      }

      {
        category = "infrastructure";
        package = terraformOutputsExtractData;
      }

      {
        category = "infrastructure";
        package = terraformInit;
      }

      {
        category = "infrastructure";
        package = encryptTo;
      }

      {
        category = "infrastructure";
        package = pkgs.cf-terraforming;
      }
    ];
  };
}
