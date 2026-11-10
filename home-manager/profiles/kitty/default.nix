{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.kitty = {
    enable = true;
    settings = {
      font_family = "monospace";
      window_padding_width = 3;
    };
    # outside noctalia's own kitty paths, whose hooks rewrite them
    extraConfig = lib.mkOrder 520 ''
      include ${config.home.homeDirectory}/.local/state/noctalia/kitty-theme.conf
    '';
  };
  home.packages = [ pkgs.kitty.terminfo ];
}
