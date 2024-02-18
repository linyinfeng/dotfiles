{self, ...}: {
  perSystem = {pkgs, ...}: let
    common = builtins.readFile ../common;

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
            # TODO
          ]);

        config = lib.mkMerge [
          {
            # TODO
          }

          # stateVersion
          {
            system.stateVersion = "${self.lib.flakeStateVersion}";
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

        message "craeting host directory..."
        mkdir --parents "nixos/hosts/$host"

        message "craeting default.nix..."
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

        message "initializing zerotier_member.host..."
        terraform-wrapper apply --target "module.hosts[\"$host\"].zerotier_member.host"

        message "creating notice..."
        cat >"prepare-host-notice-$host" <<EOF
        age key
        =======
        $(cat "$tmp_dir/key")

        manual run
        ==========
        sops-update-keys

        manual tweaks
        =============
        nixos/profiles/networking/dn42/default.nix
        EOF

        message "!!notice!!"
        cat "prepare-host-notice-$host"
      '';
    };
  in {
    devshells.default = {
      commands = [
        {
          category = "infrastructure";
          package = prepareNewHost;
        }
      ];
    };
  };
}
