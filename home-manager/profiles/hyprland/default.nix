{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}: let
  proxyCfg = osConfig.networking.fw-proxy;
  proxyUrl = "http://localhost:${toString proxyCfg.mixinConfig.mixed-port}";
  wallPaperLight = "${pkgs.nixos-artwork.wallpapers.nineish}/share/backgrounds/nixos/nix-wallpaper-nineish.png";
  wallPaperDark = "${pkgs.nixos-artwork.wallpapers.nineish-dark-gray}/share/backgrounds/nixos/nix-wallpaper-nineish-dark-gray.png";
  buildScss = name:
    pkgs.runCommand "${name}.css" {
      src = ./styles;
      nativeBuildInputs = with pkgs; [sass];
    } "sass $src/${name}.scss $out";
  swaylock = "${pkgs.swaylock-effects}/bin/swaylock";
  hyprctl = "${pkgs.hyprland}/bin/hyprctl";
in
  lib.mkIf config.home.graphical {
    wayland.windowManager.hyprland = {
      enable = true;
      recommendedEnvironment = false;
      extraConfig = ''
        ${builtins.readFile ./hyprland.conf}

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
      wofi
    ];
    programs.waybar = {
      enable = true;
      package = pkgs.waybar-hyprland;
      systemd.enable = false;
      settings = [
        {
          layer = "top";
          position = "top";
          modules-left = [
            "wlr/workspaces"
            # "wlr/taskbar"
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
    xdg.configFile."waybar/style.css".source = buildScss "waybar";
    xdg.configFile."wofi/config".source = ./wofi.conf;
    xdg.configFile."wofi/style.css".source = buildScss "wofi";
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
      daemonize = true;
      screenshots = true;
      indicator = true;
      clock = true;
      show-failed-attempts = true;
      indicator-caps-lock = true;
      grace = 5;
      font = "monospace";

      effect-blur = "10x10";
      fade-in = 5;
    };
    services.swayidle = {
      enable = true;
      systemdTarget = "hyprland-session.target";
      events = [
        {
          event = "before-sleep";
          command = swaylock;
        }
        {
          event = "lock";
          command = swaylock;
        }
      ];
      timeouts = let
        screenTimeout = 300;
        graceDelay = config.programs.swaylock.settings.grace;
      in [
        {
          timeout = screenTimeout;
          command = swaylock;
        }
        {
          timeout = screenTimeout + graceDelay;
          command = "${hyprctl} dispatch dpms off";
          resumeCommand = "${hyprctl} dispatch dpms on";
        }
      ];
    };
    xdg.configFile."hypr/hyprpaper.conf".text = ''
      preload = ${wallPaperLight}
      preload = ${wallPaperDark}

      wallpaper = , ${wallPaperLight}
    '';
  }
