{ pkgs, ... }:
let
  common = builtins.readFile ./common.sh;

  encryptTo = pkgs.writeShellApplication {
    name = "encrypt-to";
    runtimeInputs = with pkgs; [
      sops
      prettier
    ];
    text = ''
      ${common}

      plain_file="$1"
      target_file="$2"
      type="$3"
      IFS=" " read -r -a formatter <<<"$4"

      messageVerbose "encryping '$plain_file' to '$target_file' (type: '$type', formatter: '''''${formatter[*]}')..."

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
          messageVerbose "same, skipping..."
          exit 0
        fi
      fi

      EDITOR="cp '$plain_file'" \
        sops --input-type "$type" --output-type "$type" "$target_file"

      prettier --write "$target_file"
    '';
  };

  extractSecrets = pkgs.writeShellApplication {
    name = "extract-secrets";
    runtimeInputs = with pkgs; [
      sops
      (mkExtractSecret "terraform")
      (mkExtractSecret "predefined")
    ];
    text = ''
      ${common}
      sops exec-file "$SECRETS_DIR/terraform-outputs.yaml" 'extract-secrets-terraform {}'
      sops exec-file "$SECRETS_DIR/predefined.yaml"        'extract-secrets-predefined {}'
    '';
  };

  mkExtractSecret =
    secretType:
    pkgs.writeShellApplication {
      name = "extract-secrets-${secretType}";
      runtimeInputs = with pkgs; [
        encryptTo
        yq-go
        sops
        fd
      ];
      text = ''
        ${common}

        mkdir -p "$SECRETS_EXTRACT_DIR/${secretType}/hosts"

        tmp_dir=$(mktemp -t --directory encrypt.XXXXXXXXXX)
        function cleanup {
          rm -r "$tmp_dir"
        }
        trap cleanup EXIT

        cp "$1" "$tmp_dir/input.yaml"
        input_file="$tmp_dir/input.yaml"

        message "creating templates..."
        flake="$(realpath "$DOTFILES_DIR")"
        nix build "$flake#secrets-templates/${secretType}" --out-link "$tmp_dir/templates"

        message "getting host names..."
        nix build "$flake#host-names" --out-link "$tmp_dir/host-names"

        cat "$tmp_dir/host-names" | while read -r name; do
          message "extracting '${secretType}/hosts/$name.yaml'..."

          template_file="$tmp_dir/templates/$name.yq"
          plain_file="$tmp_dir/$name.plain.yaml"
          target_file="$SECRETS_EXTRACT_DIR/${secretType}/hosts/$name.yaml"

          messageVerbose "creating '$(basename "$plain_file")'..."
          yq eval --from-file "$template_file" "$input_file" >"$plain_file"

          messageVerbose "creating '$(basename "$target_file")'..."
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
        package = extractSecrets;
      }
    ];
  };
}
