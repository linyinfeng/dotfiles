{ pkgs, ... }:
let
  updatePatches = pkgs.writeShellApplication {
    name = "update-patches";
    text = ''
      cd "$PRJ_ROOT/patches"
      # currently nothing
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
