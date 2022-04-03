{ pkgs, ... }:

let
  terraform = pkgs.terraform;
in
{
  commands = [
    {
      package = terraform;
      category = "infrustructure";
    }
  ];
}
