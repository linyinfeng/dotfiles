{ pkgs, ... }:
let
  updatePatches = pkgs.writeShellApplication {
    name = "update-patches";
    text = ''
      cd "$PRJ_ROOT/patches"
      # currently nothing
      curl --location https://github.com/Alexays/Waybar/pull/3930.patch >waybar-3930.patch
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
