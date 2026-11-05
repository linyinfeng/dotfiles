{ pkgs, ... }:
{
  programs.kitty = {
    enable = true;
    settings = {
      font_family = "monospace";
      window_padding_width = 3;
    };
    autoThemeFiles = {
      dark = "noctalia";
      light = "noctalia";
      noPreference = "noctalia";
    };
  };
  home.packages = [ pkgs.kitty.terminfo ];
}
