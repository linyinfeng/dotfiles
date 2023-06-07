{...}: {
  imports = [
    ./terraform
  ];
  perSystem = {
    inputs',
    pkgs,
    ...
  }: {
    devshells.default = {
      commands = [
        {
          package = pkgs.nil;
          category = "development";
        }
        {
          package = pkgs.nerdfix;
          category = "development";
        }
        {
          package = inputs'.nixos-generators.packages.nixos-generate;
          category = "deploy";
        }
        {
          package = pkgs.sops;
          category = "secrets";
        }
        {
          category = "secrets";
          name = "sops-update-keys";
          help = "update keys for all sops file";
          command = ''
            set -e

            ${pkgs.fd}/bin/fd '.*\.yaml' $PRJ_ROOT/secrets --exec sops updatekeys --yes
          '';
        }
        {
          package = pkgs.age;
          category = "secrets";
        }
        {
          package = pkgs.age-plugin-yubikey;
          category = "secrets";
        }
        {
          package = pkgs.ssh-to-age;
          category = "secrets";
        }
      ];
    };
  };
}
