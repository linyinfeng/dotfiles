{ pkgs, ... }:
{
  programs.kitty = {
    enable = true;
    settings = {
      font_family = "monospace";
      window_padding_width = 3;
    };
  };
  home.packages = [ pkgs.kitty.terminfo ];
}
