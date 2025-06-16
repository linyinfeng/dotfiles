{ pkgs, flake-lib, ... }:
let
  common = builtins.readFile ../common.sh;

  hostDefaultNixTemplate = pkgs.writeText "host-default-template.nix" ''
    {
      suites,
      profiles,
      lib,
      ...
    }: {
      imports =
        suites.server
        ++ (with profiles; [
          # PLACEHOLDER
        ]);

      config = lib.mkMerge [
        {
          # PLACEHOLDER
        }

        # stateVersion
        {
          system.stateVersion = "${flake-lib.flakeStateVersion}";
        }
      ];
    }
  '';

  prepareNewHost = pkgs.writeShellApplication {
    name = "prepare-new-host";
    runtimeInputs = with pkgs; [
      hcledit
      age
    ];
    text = ''
      ${common}

      host="$1"
      system="$2"

      tmp_dir=$(mktemp -t --directory encrypt.XXXXXXXXXX)

      message "creating host directory..."
      mkdir --parents "nixos/hosts/$host"

      message "creating default.nix..."
      cp "${hostDefaultNixTemplate}" "nixos/hosts/$host/default.nix"

      message "creating host in nix file..."
      sed --in-place \
        '/# PLACEHOLDER new host/i \
        \
        (mkHost {\
          name = "'"$host"'";\
          system = "'"$system"'";\
        })' \
        flake/hosts.nix

      message "creating host in terraform file..."
      sed --in-place \
        '/# PLACEHOLDER new host/i '"$host"' = {\
          records      = {}\
          ddns_records = {}\
          host_indices = []\
          endpoints_v4 = []\
          endpoints_v6 = []\
        }' \
        terraform/hosts.tf

      message "creating new age key pair..."
      age-keygen --output "$tmp_dir/key"
      age_identity=$(age-keygen -y "$tmp_dir/key")

      message "updating nixago configuration..."
      sed --in-place \
        '/# PLACEHOLDER new host/i '"$host"' = {\
          key = "'"$age_identity"'";\
          owned = true;\
        };' \
        nixago/sops-yaml.nix

      message "formatting..."
      nix fmt

      message "git add..."
      git add --all

      message "creating notice..."
      cat >"prepare-host-notice-$host" <<EOF
      age key
      =======
      $(cat "$tmp_dir/key")

      manual run
      ==========
      terraform-pipe
      sops-update-keys
      EOF

      message "notice saved in 'prepare-host-notice-$host'"
      cat "prepare-host-notice-$host"
    '';
  };

  installKey = pkgs.writeShellApplication {
    name = "install-key";
    text = ''
      set  -x
      ssh "$@" sh <<EOF
        mkdir --parents /var/lib/sops-nix
        chown root:root /var/lib/sops-nix
        chmod 700 /var/lib/sops-nix
        cd /var/lib/sops-nix
        touch key
        chown root:root key
        chmod 600 key
      EOF
      ssh "$@" "cat >/var/lib/sops-nix/key"
    '';
  };
in
{
  devshells.default = {
    commands = [
      {
        category = "infrastructure";
        package = prepareNewHost;
      }
      {
        category = "infrastructure";
        package = installKey;
      }
    ];
  };
}
