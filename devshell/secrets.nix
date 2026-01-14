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

  extractTerraformOutputs = pkgs.writeShellApplication {
    name = "extract-secrets-terraform-outputs";
    runtimeInputs = with pkgs; [
      encryptTo
      yq-go
      sops
      fd
    ];
    text = ''
      ${common}

      mkdir -p "$SECRETS_EXTRACT_DIR/terraform/hosts"

      tmp_dir=$(mktemp -t --directory encrypt.XXXXXXXXXX)
      function cleanup {
        rm -r "$tmp_dir"
      }
      trap cleanup EXIT

      flake="$(realpath "$DOTFILES_DIR")"
      mapfile -t hosts < <(nix eval "$flake"#nixosConfigurations --apply 'c: (builtins.concatStringsSep "\n" (builtins.attrNames c))' --raw)
      for name in "''${hosts[@]}"; do
        message "start extracting secrets for $name from terraform outputs..."

        template_file="$tmp_dir/$name.yq"
        plain_file="$tmp_dir/$name.plain.yaml"
        target_file="$SECRETS_EXTRACT_DIR/terraform/hosts/$name.yaml"

        message "creating '$(basename "$template_file")'..."
        nix eval "$flake"#nixosConfigurations."$name".config.sops.extractTemplates.terraformOutput --raw >"$template_file"

        message "creating '$(basename "$plain_file")'..."
        sops exec-file "$SECRETS_DIR/terraform-outputs.yaml" \
          "yq eval --from-file '$template_file' {}" \
          >"$plain_file"

        message "creating '$(basename "$target_file")'..."
        encrypt-to "$plain_file" "$target_file" yaml "yq --prettyPrint"
      done
    '';
  };

  extractPredefined = pkgs.writeShellApplication {
    name = "extract-secrets-predefined";
    runtimeInputs = with pkgs; [
      encryptTo
      yq-go
      sops
      fd
    ];
    text = ''
      ${common}

      mkdir -p "$SECRETS_EXTRACT_DIR/predefined/hosts"

      tmp_dir=$(mktemp -t --directory encrypt.XXXXXXXXXX)
      function cleanup {
        rm -r "$tmp_dir"
      }
      trap cleanup EXIT

      flake="$(realpath "$DOTFILES_DIR")"
      mapfile -t hosts < <(nix eval "$flake"#nixosConfigurations --apply 'c: (builtins.concatStringsSep "\n" (builtins.attrNames c))' --raw)
      for name in "''${hosts[@]}"; do
        message "start extracting secrets for $name from predefined secrets..."

        template_file="$tmp_dir/$name.yq"
        plain_file="$tmp_dir/$name.plain.yaml"
        target_file="$SECRETS_EXTRACT_DIR/predefined/hosts/$name.yaml"

        message "creating '$(basename "$template_file")'..."
        nix eval "$flake"#nixosConfigurations."$name".config.sops.extractTemplates.predefined --raw >"$template_file"

        message "creating '$(basename "$plain_file")'..."
        sops exec-file "$SECRETS_DIR/predefined.yaml" \
          "yq eval --from-file '$template_file' {}" \
          >"$plain_file"

        message "creating '$(basename "$target_file")'..."
        encrypt-to "$plain_file" "$target_file" yaml "yq --prettyPrint"
      done
    '';
  };
in
{
  devshells.default = {
    commands = [
      {
        category = "infrastructure";
        name = "extract-secrets";
        command = ''
          set -e

          git -C "$SECRETS_DIR" pull

          extract-secrets-predefined
          extract-secrets-terraform-outputs

          nix fmt
        '';
      }

      {
        category = "infrastructure";
        package = extractPredefined;
      }

      {
        category = "infrastructure";
        package = extractTerraformOutputs;
      }
    ];
  };
}
