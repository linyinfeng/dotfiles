{ pkgs, ... }:
let
  updatePatches = pkgs.writeShellApplication {
    name = "update-patches";
    text = ''
      cd "$PRJ_ROOT/patches"
      curl https://gitlab.gnome.org/GNOME/mutter/-/merge_requests/3751.patch > mutter-text-input-v1.patch
      curl https://gitlab.gnome.org/GNOME/gnome-shell/-/merge_requests/3318.patch > gnome-shell-preedit-fix.patch
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
