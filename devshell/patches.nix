{ pkgs, ... }:
let
  updatePatches = pkgs.writeShellApplication {
    name = "update-patches";
    text = ''
      echo "updating patches..."
      pushd "$PRJ_ROOT/patches" >/dev/null
      # currently nothing
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
