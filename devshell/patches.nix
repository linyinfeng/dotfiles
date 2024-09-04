{ pkgs, ... }:
let
  updatePatches = pkgs.writeShellApplication {
    name = "update-patches";
    text = ''
      cd "$PRJ_ROOT/patches"
      # TODO broken on newest commits
      # curl https://gitlab.gnome.org/GNOME/mutter/-/merge_requests/3751.patch >mutter-text-input-v1.patch
      curl https://gitlab.gnome.org/GNOME/gnome-shell/-/merge_requests/3318.patch >gnome-shell-preedit-fix.patch
      curl https://patch-diff.githubusercontent.com/raw/Alexays/Waybar/pull/3551.patch >waybar-niri.patch
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
