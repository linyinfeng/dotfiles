{ pkgs, ... }:
let
  updatePatches = pkgs.writeShellApplication {
    name = "update-patches";
    text = ''
      cd "$PRJ_ROOT/patches"
      # TODO broken on newest commits
    '';
  };
in
{
  devshells.default = {
    commands = [
      {
        package = updatePatches;
        category = "patches";
      }
    ];
  };
}
