{ ... }:
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
        "themes/noctalia.toml"
      ];
    };
  };
}
