{
  pkgs,
  lib,
  self',
  ...
}:
let
  sopsYaml = (pkgs.formats.yaml { }).generate "sops.yaml" (import ./sops-yaml.nix { inherit lib; });
in
{
  imports = [ ./envs.nix ];
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
    devshell.startup.sops-yaml.text = ''
      ln -sfn ${sopsYaml} "$PRJ_ROOT/.sops.yaml"
    '';
  };
}
