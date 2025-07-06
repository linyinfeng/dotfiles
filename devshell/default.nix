{ pkgs, ... }:
{
  imports = [
    ./terraform.nix
    ./boot-sd.nix
    ./patches.nix
    ./kernel-config.nix
    ./enchilada.nix
    ./prepare
  ];
  devshells.default = {
    commands = [
      {
        package = pkgs.sops;
        category = "secrets";
      }
      {
        category = "secrets";
        name = "sops-update-keys";
        help = "update keys for all sops file";
        command = ''
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
}
