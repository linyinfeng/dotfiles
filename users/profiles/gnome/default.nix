{ pkgs, lib, ... }:
let
  extensionPkgs = with pkgs.gnomeExtensions; [
    # arc-menu
    # gsconnect
    # dash-to-dock
    # dash-to-panel
    appindicator
    # caffeine
  ];
in
{
  home.packages = extensionPkgs;

  programs.chromium.extensions = [
    "gphhapmejobijbbhgpjhcjognlahblep" # GNOME Shell integration
    # "jfnifeihccihocjbfcfhicmmgpjicaec" # GSConnect
  ];

  # Remove initial setup dialog
  home.file.".config/gnome-initial-setup-done".text = "yes";

  dconf.settings = {
    # Do not sleep when ac power connected
    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
    };
  };

  programs.gnome-terminal =
    let defaultProfile = "b1dcc9dd-5262-4d8d-a863-c897e6d979b9";
    in
    {
      enable = true;
      profile.${defaultProfile} = {
        visibleName = "Main";
        default = true;
        font = "DejaVu Sans Mono for Powerline 10";
      };
    };

  home.activation.allowGdmReadFace = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.acl}/bin/setfacl --modify=group:gdm:--x "$HOME"
  '';
}
