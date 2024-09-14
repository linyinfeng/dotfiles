{ pkgs, lib, ... }:
let
  themeFile = ".config/alacritty/theme.toml";
  darkmanSwitch = pkgs.writeShellApplication {
    name = "darkman-switch-alacritty";
    text = ''
      mode="$1"
      ln --force --symbolic "${pkgs.alacritty-theme}/github_$mode.toml" "$HOME/${themeFile}"
      touch "$XDG_CONFIG_HOME/alacritty/alacritty.toml"
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
        themeFile
      ];
    };
  };
  systemd.user.tmpfiles.rules = [
    # link theme if not exists
    "L %h/${themeFile} - - - - ${pkgs.alacritty-theme}/github_light.toml"
  ];
  services.darkman = {
    lightModeScripts.alacritty = "${lib.getExe darkmanSwitch} light";
    darkModeScripts.alacritty = "${lib.getExe darkmanSwitch} dark";
  };
}
