{ lib, ... }:

# TODO disabled
lib.mkIf false {
  wayland.windowManager.sway = {
    enable = true;
    systemdIntegration = true;
    config = {
      modifier = "Mod4";
      startup = [
      ];
      terminal = "alacritty";
      bars = [ ]; # use waybar instead
    };
  };
  services.kanshi = {
    enable = true;
  };
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = [
      {
        layer = "bottom";
        position = "top";
        modules-left = [
          "sway/workspaces"
          "wlr/taskbar"
          "sway/mode"
        ];
        modules-center = [
          "sway/window"
        ];
        modules-right = [
          "network"
          "temperature"
          "battery"
          "backlight"
          "pulseaudio"
          "clock"
          "tray"
        ];
        modules = {
          "wlr/taskbar" = {
            all-outputs = false;
            on-click = "activate";
            on-click-middle = "close";
          };
        };
      }
    ];
  };
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        normal.family = "Sarasa Mono Slab SC";
        size = 11.0;
      };
      colors = {
        primary = {
          foreground = "#171421";
          background = "#FFFFFF";
        };
        normal = {
          black = "#171421";
          red = "#C01C28";
          green = "#26A269";
          yellow = "#A2734C";
          blue = "#12488B";
          magenta = "#A347BA";
          cyan = "#2AA1B3";
          white = "#D0CFCC";
        };
        bright = {
          black = "#5E5C64";
          red = "#F66151";
          green = "#33D17A";
          yellow = "#E9AD0C";
          blue = "#2A7BDE";
          magenta = "#C061CB";
          cyan = "#33C7DE";
          white = "#FFFFFF";
        };
      };
    };
  };
}
