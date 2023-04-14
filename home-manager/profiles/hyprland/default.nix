{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}: let
  proxyCfg = osConfig.networking.fw-proxy;
  proxyUrl = "http://localhost:${toString proxyCfg.mixinConfig.mixed-port}";
in
  lib.mkIf config.home.graphical {
    wayland.windowManager.hyprland = {
      enable = true;
      extraConfig = ''
        ${
          builtins.readFile ./hyprland.conf
        }

        ${
          lib.optionalString proxyCfg.enable ''
            env = HTTP_PROXY,${proxyUrl}
            env = http_proxy,${proxyUrl}
            env = HTTPS_PROXY,${proxyUrl}
            env = https_proxy,${proxyUrl}
          ''
        }
      '';
    };
    home.packages = with pkgs; [
      hyprpaper
      hyprpicker
      clipman
      kitty
      wofi
      eww-wayland
    ];
    programs.waybar = {
      enable = true;
      package = pkgs.waybar-hyprland;
      systemd.enable = true;
      settings = [
        {
          layer = "top";
          position = "top";
          modules-left = [
            "wlr/workspaces"
            # "wlr/taskbar" # broken in systemd service
          ];
          modules-center = [
            # "wlr/window"
          ];
          modules-right = [
            "tray"
            "network"
            "battery"
            "backlight"
            "pulseaudio"
            # "wireplumber" # broken on multiple outputs
            "clock"
          ];
          "wlr/workspaces" = {
            format = "{name}";
            on-click = "activate";
            on-scroll-up = "hyprctl dispatch workspace e+1";
            on-scroll-down = "hyprctl dispatch workspace e-1";
          };
          "wlr/taskbar" = {
            all-outputs = false;
            on-click = "activate";
            on-click-middle = "close";
          };
          "network" = {
            format = "{ifname}";
            format-wifi = "{essid} ";
            format-ethernet = "{ifname} ";
            format-disconnected = ""; # An empty format will hide the module.
            tooltip-format = "{ifname} via {gwaddr}";
            tooltip-format-wifi = "{essid} ({signalStrength}%) ";
            tooltip-format-ethernet = "{ipaddr}/{cidr} ";
          };
          "pulseaudio" = {
            format = "{volume}% {icon}";
            format-bluetooth = "{volume}% {icon}";
            format-muted = "";
            format-icons = {
              default = ["" "" ""];
            };
            scroll-step = 1;
          };
          "wireplumber" = {
            format = "{volume}% {icon}";
            format-muted = "";
            format-icons = ["" "" ""];
          };
          "backlight" = {
            format = "{percent}% {icon}";
            format-icons = ["" ""];
            on-scroll-up = "sudo light -A 1";
            on-scroll-down = "sudo light -U 1";
          };
          "battery" = {
            interval = 60;
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{capacity}% {icon}";
            format-icons = ["" "" "" "" ""];
          };
          "clock" = {
            format = "{:%Y-%m-%d %H:%M} ";
          };
          "tray" = {
            spacing = 5;
          };
        }
      ];
    };
    xdg.configFile."waybar/style.css".source =
      pkgs.runCommand "waybar-style.css" {
        src = ./.;
        nativeBuildInputs = with pkgs; [
          sass
        ];
      } ''
        sass $src/waybar.scss $out
      '';
    xdg.configFile."wofi/config".source = ./wofi.conf;
    xdg.configFile."wofi/style.css".source =
      pkgs.runCommand "wofi-style.css" {
        src = ./.;
        nativeBuildInputs = with pkgs; [
          sass
        ];
      } ''
        sass $src/wofi.scss $out
      '';
    services.dunst = {
      enable = true;
      settings = {
        global = {
          follow = "keyboard";
          enable_posix_regex = true;
          origin = "top-right";
          offset = "16x16";
          font = "monospace 12";
          corner_radius = 5;
        };
      };
    };
    programs.swaylock.settings = {
      color = "000000";
    };
    xdg.configFile."hypr/hyperpaper.conf".text = ''
      preload = ${pkgs.gnome.gnome-backgrounds}/share/backgrounds/gnome/symbolic-l.webp
      preload = ${pkgs.gnome.gnome-backgrounds}/share/backgrounds/gnome/symbolic-d.webp

      wallpaper = , ${pkgs.gnome.gnome-backgrounds}/share/backgrounds/gnome/symbolic-l.webp
    '';
  }
