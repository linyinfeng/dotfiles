{ pkgs, ... }:

{
  commands = [
    {
      category = "infrastructure";
      name = "terraform-wrapper";
      help = pkgs.terraform.meta.description;
      command = ''
        set -e

        export PATH=${pkgs.zerotierone}/bin:${pkgs.minio-client}/bin:$PATH

        encrypted_state_file="$PRJ_ROOT/secrets/terraform.tfstate"
        unencrypted_state_file="$PRJ_ROOT/terraform/terraform.tfstate"
        echo "decrypt terraform state to '$unencrypted_state_file'..." >&2
        sops --decrypt "$encrypted_state_file" > "$unencrypted_state_file"

        function cleanup {
          cd $PRJ_ROOT
          if [ -n "$(cat "$unencrypted_state_file")" ]; then
            echo "encrypt terraform state to '$encrypted_state_file'..." >&2
            sops --encrypt "$unencrypted_state_file" > "$encrypted_state_file"
            rm "$unencrypted_state_file"
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
        sops --encrypt "$unencrypted_output_file" > "$encrypted_output_file"
        rm "$unencrypted_output_file"
      '';
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
