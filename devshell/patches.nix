{ pkgs, ... }:
let
  updatePatches = pkgs.writeShellApplication {
    name = "update-patches";
    text = ''
      echo "updating patches..."
      pushd "$PRJ_ROOT/patches" >/dev/null
      # currently nothing
      curl --location https://github.com/Alexays/Waybar/pull/3930.patch >waybar-3930.patch
      popd >/dev/null
    '';
  };
in
{
  devshells.default = {
    commands = [
      {
        package = updatePatches;
        category = "data";
      }
    ];
  };
}
