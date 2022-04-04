{ pkgs, ... }:

let
  command = package: { category = "infrustructure"; inherit package; };
  terraform = pkgs.terraform;
  terraform-env = pkgs.writeShellScriptBin "terraform-env" ''
    ${pkgs.sops}/bin/sops exec-env ../secrets/terraform.yaml ${pkgs.fish}/bin/fish
  '';
in
{
  commands = [
    (command terraform)
    (command terraform-env)
    (command pkgs.nur.repos.linyinfeng.cf-terraforming)
  ];
}
