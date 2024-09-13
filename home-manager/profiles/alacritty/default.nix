{ pkgs, ... }:
{
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        dynamic_padding = true;
      };
      import = [
        "${pkgs.alacritty-theme}/github_light.toml"
      ];
    };
  };
}
