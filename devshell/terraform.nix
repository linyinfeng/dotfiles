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
      stage="''${1:-$TERRAFORM_STAGE}"
      shift || true
      case "$stage" in
        pre-nixos|post-nixos) ;;
        *) message "unknown terraform stage: $stage"; exit 2 ;;
      esac
      root="$TERRAFORM_DIR/stages/$stage"
      if [ ! -d "$root" ]; then
        message "terraform root does not exist for stage: $stage"
        exit 2
      fi
      root="$(realpath "$root")"
      TF_DATA_DIR="$root/.terraform-data" terraform -chdir="$root" init -backend-config="path=$root/terraform.tfstate" "$@"
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
      xray
      encryptTo
    ];
    text = ''
      ${common}

      stage="''${TERRAFORM_STAGE:-pre-nixos}"
      case "$stage" in
        pre-nixos|post-nixos) ;;
        *) message "unknown terraform stage: $stage"; exit 2 ;;
      esac
      root="$TERRAFORM_DIR/stages/$stage"
      if [ ! -d "$root" ]; then
        message "terraform root does not exist for stage: $stage"
        exit 2
      fi
      root="$(realpath "$root")"
      state_dir="$SECRETS_DIR/terraform/states"
      encrypted="$state_dir/$stage.tfstate"
      plain="$root/terraform.tfstate"
      export TF_DATA_DIR="$root/.terraform-data"

      if [ ! -e "$encrypted" ] && [ "$stage" = "pre-nixos" ] && [ -e "$SECRETS_DIR/terraform.tfstate" ]; then
        encrypted="$SECRETS_DIR/terraform.tfstate"
        message "using legacy encrypted state for pre-nixos"
      fi

      message "decrypt terraform state to '$plain'..."
      if [ ! -e "$encrypted" ]; then
        message "encrypted state is missing: $encrypted"
        message "refusing to run Terraform without an explicitly migrated state"
        exit 2
      fi
      sops --input-type json --output-type json --decrypt "$encrypted" >"$plain"

      function cleanup {
        exit_code=$?

        set -e

        if [ -s "$plain" ]; then
          encrypt-to "$plain" "$encrypted" json "yq --prettyPrint"
        fi
        message "deleting terraform state '$plain'..."
        rm -f "$plain"* # remove plain and backup files

        message "terraform exit code: $exit_code"
        exit $exit_code
      }
      trap cleanup EXIT
      trap 'exit 130' INT
      trap 'exit 143' TERM

      set +e
      terraform -chdir="$root" "$@"
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
      trap 'exit 130' INT
      trap 'exit 143' TERM

      stage="''${1:-$TERRAFORM_STAGE}"
      shift || true
      case "$stage" in
        pre-nixos|post-nixos) ;;
        *) message "unknown terraform stage: $stage"; exit 2 ;;
      esac
      plain_output="$tmp_dir/terraform-outputs.plain.yaml"

      TERRAFORM_STAGE="$stage" terraform-wrapper output --json "$@" >"$plain_output"
      mkdir -p "$SECRETS_DIR/terraform/outputs"
      encrypt-to "$plain_output" "$SECRETS_DIR/terraform/outputs/$stage.yaml" yaml "yq --prettyPrint"
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

      stage="''${1:-pre-nixos}"
      shift || true
      if [ "$stage" != "pre-nixos" ]; then
        message "NixOS data can only be extracted from pre-nixos outputs"
        exit 2
      fi
      output_file="$SECRETS_DIR/terraform/outputs/$stage.yaml"
      if [ ! -e "$output_file" ] && [ -e "$SECRETS_DIR/terraform-outputs.yaml" ]; then
        output_file="$SECRETS_DIR/terraform-outputs.yaml"
      fi
      format="json"
      message "creating 'data.$format'..."
      sops exec-file "$output_file" \
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

          stage="''${1:-$TERRAFORM_STAGE}"
          if [ "$#" -gt 0 ]; then shift; fi
          case "$stage" in
            pre-nixos|post-nixos) ;;
            *) message "unknown terraform stage: $stage"; exit 2 ;;
          esac

          git -C "$SECRETS_DIR" pull --ff-only
          function cleanup {
            exit_code=$?
            if [ "$exit_code" -ne 0 ]; then
              return "$exit_code"
            fi
            git -C "$SECRETS_DIR" add --all
            if ! git -C "$SECRETS_DIR" diff --cached --quiet; then
              git -C "$SECRETS_DIR" commit --message "Terraform $stage apply"
              git -C "$SECRETS_DIR" push
            fi
          }
          trap cleanup EXIT

          terraform-init "$stage"
          TERRAFORM_STAGE="$stage" terraform-wrapper apply "$@"
          terraform-update-outputs "$stage"
          if [ "$stage" = "pre-nixos" ]; then
            terraform-outputs-extract-data "$stage"
            extract-secrets-terraform-only
          fi

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
