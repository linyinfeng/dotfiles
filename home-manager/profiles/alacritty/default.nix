{ pkgs, lib, ... }:
let
  # an empty file used to trigger config hot reloading
  touchFile = ".config/alacritty/touch.toml";
  themeFile = ".config/alacritty/theme.toml";
  darkmanSwitch = pkgs.writeShellApplication {
    name = "darkman-switch-alacritty";
    text = ''
      mode="$1"
      ln --force --symbolic "${pkgs.alacritty-theme}/github_$mode.toml" "$HOME/${themeFile}"
      touch "$HOME/${touchFile}"
    '';
  };
in
{
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding = {
          x = 3;
          y = 3;
        };
      };
      import = [
        touchFile
        themeFile
      ];
    };
  };
  systemd.user.tmpfiles.rules = [
    # link theme if not exists
    "L %h/${themeFile} - - - - ${pkgs.alacritty-theme}/github_light.toml"
    "f %h/${touchFile} - - - -"
  ];
  services.darkman = {
    lightModeScripts.alacritty = "${lib.getExe darkmanSwitch} light";
    darkModeScripts.alacritty = "${lib.getExe darkmanSwitch} dark";
  };
}
