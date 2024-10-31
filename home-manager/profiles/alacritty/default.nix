{ pkgs, lib, ... }:
let
  toml = pkgs.formats.toml { };
  themeFile = "theme.toml";
  themeToml = toml.generate "theme.toml" {
    general.import = [
      "${pkgs.alacritty-theme}/github_light.toml"
    ];
  };
  darkmanSwitch = pkgs.writeShellApplication {
    name = "darkman-switch-alacritty";
    runtimeInputs = with pkgs; [
      toml-cli
      moreutils
    ];
    text = ''
      mode="$1"
      pushd "$HOME/.config/alacritty"

      toml set "${themeFile}" "general.import[0]" "${pkgs.alacritty-theme}/github_$mode.toml" | sponge "${themeFile}"

      popd
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
      general.import = [
        themeFile
      ];
    };
  };
  systemd.user.tmpfiles.rules = [
    # link theme if not exists
    "C %h/.config/alacritty/${themeFile} - - - - ${themeToml}"
    "z %h/.config/alacritty/${themeFile} 644 - - -"
  ];
  services.darkman = {
    lightModeScripts.alacritty = "${lib.getExe darkmanSwitch} light";
    darkModeScripts.alacritty = "${lib.getExe darkmanSwitch} dark";
  };
}
