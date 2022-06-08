{ pkgs, ... }:

{
  commands = [
    {
      category = "infrastructure";
      name = "terraform";
      help = pkgs.terraform.meta.description;
      command = ''
        set -e

        encrypted_state_file="$PRJ_ROOT/secrets/terraform.tfstate"
        unencrypted_state_file="$PRJ_ROOT/terraform/terraform.tfstate"
        echo "decrypt terraform state to '$unencrypted_state_file'..."
        sops --decrypt "$encrypted_state_file" > "$unencrypted_state_file"

        function cleanup {
          cd $PRJ_ROOT
          echo "encrypt terraform state to '$encrypted_state_file'..."
          sops --encrypt "$unencrypted_state_file" > "$encrypted_state_file"
          rm "$unencrypted_state_file"
        }
        trap cleanup EXIT

        cd $PRJ_ROOT/terraform
        ${pkgs.terraform}/bin/terraform "$@"
      '';
    }
  ];
}
