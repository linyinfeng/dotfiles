{ ... }:

# TODO: not finished yet
{
  wayland.windowManager.sway = {
    enable = true;
    config = {
      modifier = "Mod4";
      startup = [
      ];
      terminal = "alacritty";
    };
  };
  services.kanshi = {
    enable = true;
  };
  programs.waybar = {
    enable = true;
    settings = [
      {
        layer = "bottom";
        position = "top";
        modules-left = [
          "sway/workspaces"
          "sway/mode"
        ];
        modules-center = [
          "sway/window"
        ];
        modules-right = [
          "battery"
          "clock"
        ];
        modules = { };
      }
    ];
  };
  programs.alacritty = {
    enable = true;
  };
}
