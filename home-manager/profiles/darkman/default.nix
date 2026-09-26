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
}
