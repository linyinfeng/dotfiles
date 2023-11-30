{...}: {
  perSystem = {pkgs, ...}: let
    common = ''
      function message {
        green='\033[0;32m'
        no_color='\033[0m'
        echo -e "$green>$no_color $1" >&2
      }
    '';

    encryptTo = pkgs.writeShellApplication {
      name = "encrypt-to";
      runtimeInputs = with pkgs; [
        sops
      ];
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
      runtimeInputs = with pkgs; [
        terraform
      ];
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
        jq
        openssl
        ruby
        yq-go
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

        message "creating 'data.json'..."

        # TODO workaround https://github.com/mikefarah/yq/issues/1880
        sops exec-file "$SECRETS_DIR/terraform-outputs.yaml" \
          "yq eval --from-file \"$DATA_EXTRACT_DIR/template.yq\" {} --output-format yaml" \
          >"$DATA_EXTRACT_DIR/data.yaml"
        yq "$DATA_EXTRACT_DIR/data.yaml" --output-format json >"$DATA_EXTRACT_DIR/data.json"
        rm "$DATA_EXTRACT_DIR/data.yaml"
      '';
    };

    terraformOutputsExtractSecrets = pkgs.writeShellApplication {
      name = "terraform-outputs-extract-secrets";
      runtimeInputs = with pkgs; [
        encryptTo
        yq-go
        sops
        fd
      ];
      text = ''
        ${common}

        mkdir -p terraform/hosts

        tmp_dir=$(mktemp -t --directory encrypt.XXXXXXXXXX)
        mkdir "$tmp_dir/hosts"
        function cleanup {
          rm -r "$tmp_dir"
        }
        trap cleanup EXIT

        function extract {
          name="$1"
          is_host="$2"

          if [ "$is_host" != "is_host" ]; then
            template_file="$SECRETS_EXTRACT_DIR/templates/$name.yq"

            plain_file="$tmp_dir/$name.plain.yaml"

            target_file="$SECRETS_EXTRACT_DIR/terraform/$name.yaml"
          else
            export hostname="$name"
            template_file="$SECRETS_EXTRACT_DIR/templates/hosts/$name.yq"
            host_template_file="$SECRETS_EXTRACT_DIR/templates/host.yq"

            plain_file="$tmp_dir/hosts/$name.plain.yaml"
            host_plain_file="$tmp_dir/$name.host.plain.yaml"

            target_file="$SECRETS_EXTRACT_DIR/terraform/hosts/$name.yaml"
          fi

          message "creating '$plain_file'..."
          sops exec-file "$SECRETS_DIR/terraform-outputs.yaml" \
            "yq eval --from-file '$template_file' {}" \
            >"$plain_file"

          if [ "$is_host" = "is_host" ]; then
            message "creating '$host_plain_file'..."
            sops exec-file "$SECRETS_DIR/terraform-outputs.yaml" \
              "yq eval --from-file '$host_template_file' {}" \
              >"$host_plain_file"

            message "merging '$host_plain_file' into '$plain_file'..."
            yq --inplace ". *= load(\"$host_plain_file\")" "$plain_file"
          fi

          encrypt-to "$plain_file" "$target_file" yaml "yq --prettyPrint"
        }

        extract common not_host
        extract infrastructure not_host

        mapfile -t host_names < <(fd '^.*\.yq$' "$SECRETS_EXTRACT_DIR/templates/hosts" --exec echo '{/.}')
        for host_name in "''${host_names[@]}"; do
          extract "$host_name" is_host
        done
      '';
    };
  in {
    devshells.default = {
      env = [
        {
          name = "TERRAFORM_DIR";
          eval = "\${TERRAFORM_DIR:-$PRJ_ROOT/terraform}";
        }
        {
          name = "SECRETS_DIR";
          eval = "\${SECRETS_DIR:-$(realpath \"$PRJ_ROOT/../infrastructure-secrets\")}";
        }
        {
          name = "TF_VAR_terraform_input_path";
          eval = "\${TF_VAR_terraform_input_path:-$SECRETS_DIR/terraform-inputs.yaml}";
        }
        {
          name = "DATA_EXTRACT_DIR";
          eval = "\${DATA_EXTRACT_DIR:-$PRJ_ROOT/lib/data}";
        }
        {
          name = "SECRETS_EXTRACT_DIR";
          eval = "\${SECRETS_EXTRACT_DIR:-$PRJ_ROOT/secrets}";
        }
      ];
      commands = [
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
          package = terraformWrapper;
        }

        {
          category = "infrastructure";
          package = terraformUpdateOutputs;
        }

        {
          category = "infrastructure";
          package = terraformOutputsExtractSecrets;
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
          package = pkgs.cf-terraforming;
          category = "infrastructure";
        }
      ];
    };
  };
}
