{ pkgs, lib, ... }:

let
  switchGnome = pkgs.writeShellApplication {
    name = "darkman-switch-gnome";
    runtimeInputs = with pkgs; [
      glib
    ];
    text = ''
      mode="$1"
      gsettings set org.gnome.desktop.interface color-scheme "prefer-$mode"
    '';
  };
in
{
  services.darkman = {
    enable = true;
    lightModeScripts = {
      gnome = "${lib.getExe switchGnome} light";
    };
    darkModeScripts = {
      gnome = "${lib.getExe switchGnome} dark";
    };
  };
}
