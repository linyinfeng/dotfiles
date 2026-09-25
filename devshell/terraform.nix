{ pkgs, ... }:
let
  common = builtins.readFile ./common.sh;

  # Stage registry: the TF_VAR_* each stage declares. The wrapper exports them
  # from here, so a stage never carries the other stage's variables around
  # (terraform warns about values for undeclared variables).
  stages = {
    pre-nixos = {
      "terraform_input_path" = "\${SECRETS_DIR}/terraform-inputs.yaml";
      "predefined_secrets_path" = "\${SECRETS_DIR}/predefined.yaml";
    };
    post-nixos = {
      "terraform_input_path" = "\${SECRETS_DIR}/terraform-inputs.yaml";
      # stage interface: the previous stage's encrypted outputs
      "pre_nixos_outputs_path" = "\${SECRETS_DIR}/terraform/outputs/pre-nixos.yaml";
    };
  };
  stageNames = builtins.attrNames stages;
  allStageVars = builtins.attrNames (
    builtins.foldl' (acc: name: acc // stages.${name}) { } stageNames
  );

  # there is no default stage: every command has to be told which one to run
  requireStage = ''
    if [ -z "$stage" ]; then
      echo "no terraform stage given: pass it as the first argument (e.g. pre-nixos) or set TERRAFORM_STAGE" >&2
      exit 2
    fi
  '';

  # a leading stage argument wins over the environment
  takeStageArg = ''
    case "''${1:-}" in
      ${builtins.concatStringsSep "|" stageNames})
        stage="$1"
        shift
        ;;
    esac
  '';

  stageCheck = ''
    case "$stage" in
      ${builtins.concatStringsSep "|" stageNames}) ;;
      *) echo "unknown terraform stage: $stage" >&2; exit 2 ;;
    esac
  '';

  # one TF_VAR export line per variable the stage declares
  mkExport = name: var: "    export TF_VAR_${var}=\"\${TF_VAR_${var}:-${stages.${name}.${var}}}\"";

  # a stage gets exactly the variables it declares: the other stages' TF_VARs
  # are unset (terraform warns about values for undeclared variables), while a
  # value that is already set from outside still wins
  mkStageVars =
    name:
    builtins.concatStringsSep "\n" (
      map (var: "    unset TF_VAR_${var}") (
        builtins.filter (var: !builtins.hasAttr var stages.${name}) allStageVars
      )
      ++ map (mkExport name) (builtins.attrNames stages.${name})
    );

  stageVarSetup = builtins.concatStringsSep "\n" (
    [ "# stage inputs, generated from the devshell stage registry" ]
    ++ [ "case \"$stage\" in" ]
    ++ builtins.concatLists (
      map (name: [
        "  ${name})"
        (mkStageVars name)
        "    ;;"
      ]) stageNames
    )
    ++ [ "esac" ]
  );

  # stages in dependency order; asserted against the registry below
  stageOrder =
    assert
      builtins.sort builtins.lessThan [
        "pre-nixos"
        "post-nixos"
      ] == builtins.sort builtins.lessThan stageNames;
    [
      "pre-nixos"
      "post-nixos"
    ];

  # one stage of the pipeline: init, apply, refresh that stage's outputs and, for
  # pre-nixos, the NixOS inputs derived from them
  terraformApplyStage = pkgs.writeShellApplication {
    name = "terraform-apply-stage";
    runtimeInputs = with pkgs; [
      terraform
      terraformInit
      terraformWrapper
      terraformUpdateOutputs
      terraformOutputsExtractData
    ];
    text = ''
      ${common}

      stage="''${1:-''${TERRAFORM_STAGE:-}}"
      shift || true
      ${requireStage}
      ${stageCheck}

      terraform-init "$stage"
      TERRAFORM_STAGE="$stage" terraform-wrapper apply "$@"
      terraform-update-outputs "$stage"
      if [ "$stage" = "pre-nixos" ]; then
        terraform-outputs-extract-data "$stage"
        extract-secrets-terraform-only
      fi
    '';
  };

  # commit the state/outputs a successful pipeline produced
  terraformCommitOutputs = pkgs.writeShellApplication {
    name = "terraform-commit-outputs";
    runtimeInputs = with pkgs; [ git ];
    text = ''
      ${common}

      git -C "$SECRETS_DIR" add --all
      if git -C "$SECRETS_DIR" diff --cached --quiet; then
        message "secrets repository is clean, nothing to commit"
      else
        git -C "$SECRETS_DIR" commit --message "$1"
        git -C "$SECRETS_DIR" push
      fi
    '';
  };

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
      stage="''${1:-''${TERRAFORM_STAGE:-}}"
      shift || true
      ${requireStage}
      ${stageCheck}
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

      stage="''${TERRAFORM_STAGE:-}"
      ${takeStageArg}
      ${requireStage}
      ${stageCheck}
      root="$TERRAFORM_DIR/stages/$stage"
      if [ ! -d "$root" ]; then
        message "terraform root does not exist for stage: $stage"
        exit 2
      fi
      root="$(realpath "$root")"

      ${stageVarSetup}

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

      stage="''${1:-''${TERRAFORM_STAGE:-}}"
      shift || true
      ${requireStage}
      ${stageCheck}
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

          stage="''${1:-''${TERRAFORM_STAGE:-}}"
          if [ "$#" -gt 0 ]; then shift; fi
          ${requireStage}
          ${stageCheck}

          git -C "$SECRETS_DIR" pull --ff-only
          function cleanup {
            exit_code=$?
            if [ "$exit_code" -ne 0 ]; then
              return "$exit_code"
            fi
            terraform-commit-outputs "Terraform $stage apply"
          }
          trap cleanup EXIT

          terraform-apply-stage "$stage" "$@"

          nix fmt
        '';
      }

      {
        category = "infrastructure";
        name = "terraform-pipe-all";
        help = "run every stage in dependency order, publishing the NixOS inputs after pre-nixos";
        command = ''
          set -e

          git -C "$SECRETS_DIR" pull --ff-only
          function cleanup {
            exit_code=$?
            if [ "$exit_code" -ne 0 ]; then
              return "$exit_code"
            fi
            terraform-commit-outputs "Terraform ${builtins.concatStringsSep "+" stageOrder} apply"
            nix fmt
          }
          trap cleanup EXIT

          for stage in ${builtins.concatStringsSep " " stageOrder}; do
            echo "== stage: $stage"
            terraform-apply-stage "$stage" "$@"
          done
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
        package = terraformApplyStage;
      }

      {
        category = "infrastructure";
        package = terraformCommitOutputs;
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
