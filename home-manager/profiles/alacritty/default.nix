{ pkgs, ... }:
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
        "${pkgs.alacritty-theme}/github_light.toml"
      ];
    };
  };
}
