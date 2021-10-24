{ config, pkgs, lib, ... }:
let
  extensionPkgs = with pkgs.gnomeExtensions; [
    # arc-menu
    gsconnect
    # dash-to-dock
    dash-to-panel
    appindicator
    # caffeine
    gtile
  ];
in
lib.mkIf
  config.passthrough.systemConfig.services.xserver.desktopManager.gnome.enable
{
  home.packages = extensionPkgs;

  programs.chromium.extensions = [
    "gphhapmejobijbbhgpjhcjognlahblep" # GNOME Shell integration
    "jfnifeihccihocjbfcfhicmmgpjicaec" # GSConnect
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
        default = true;
        visibleName = "Main";
        font = "Sarasa Term Slab SC 10";
        scrollOnOutput = false;
      };
    };

  home.activation.allowGdmReadFace = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.acl}/bin/setfacl --modify=group:gdm:--x "$HOME"
  '';

  # gsconnect association
  xdg.mimeApps.associations.added = {
    "x-scheme-handler/sms" = "org.gnome.Shell.Extensions.GSConnect.desktop";
    "x-scheme-handler/tel" = "org.gnome.Shell.Extensions.GSConnect.desktop";
  };
}
