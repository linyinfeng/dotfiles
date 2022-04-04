{ pkgs, ... }:

let
  command = package: { category = "infrustructure"; inherit package; };
  terraform = pkgs.terraform;
in
{
  commands = [
    (command terraform)
    (command pkgs.nur.repos.linyinfeng.cf-terraforming)
  ];
}
