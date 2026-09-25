{ pkgs, self', ... }:
{
  imports = [
    ./envs.nix
    ./boot-sd.nix
    ./patches.nix
    ./prepare
  ];
  devshells.default = {
    commands = [
      {
        package = pkgs.sops;
        category = "secrets";
      }
      {
        package = self'.packages.maintain;
        category = "secrets";
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
