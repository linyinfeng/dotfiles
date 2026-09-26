{ pkgs, lib, ... }:

let
  switchGtk = pkgs.writeShellApplication {
    name = "darkman-switch-gtk";
    runtimeInputs = with pkgs; [
      glib
    ];
    text = ''
      mode="$1"
      gsettings set org.gnome.desktop.interface color-scheme "prefer-$mode"
    '';
  };
in
lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  services.darkman = {
    enable = true;
    settings = {
      dbusserver = true;
      portal = true;
    };
    lightModeScripts = {
      gtk = "${lib.getExe switchGtk} light";
    };
    darkModeScripts = {
      gtk = "${lib.getExe switchGtk} dark";
    };
  };
  # D-Bus activatable and BindsTo=graphical-session.target; without a display
  # check the activation drags graphical-session.target into ssh sessions.
  systemd.user.services.darkman.Unit.ConditionEnvironment = [
    "|WAYLAND_DISPLAY"
    "|DISPLAY"
  ];
}
