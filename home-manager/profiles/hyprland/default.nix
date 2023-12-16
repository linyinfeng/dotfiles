{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}: let
  wallPaperLight = "${pkgs.nixos-artwork.wallpapers.nineish}/share/backgrounds/nixos/nix-wallpaper-nineish.png";
  wallPaperDark = "${pkgs.nixos-artwork.wallpapers.nineish-dark-gray}/share/backgrounds/nixos/nix-wallpaper-nineish-dark-gray.png";
  buildScss = name:
    pkgs.runCommand "${name}.css" {
      src = ./_styles;
      nativeBuildInputs = with pkgs; [sass];
    } "sass $src/${name}.scss $out";
  swaylock = "${pkgs.swaylock-effects}/bin/swaylock";
  hyprctl = "${pkgs.hyprland}/bin/hyprctl";

  proxyCfg = osConfig.networking.fw-proxy;
  variables = lib.optionalAttrs proxyCfg.enable proxyCfg.environment;
  mkVariableCfg = name: value: "env = ${name},${value}";
in {
  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = ''
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList mkVariableCfg variables)}

      ${builtins.readFile ./hyprland.conf}
    '';
  };
  home.packages = with pkgs; [
    hyprpaper
    hyprpicker
    avizo
    clipman
    wofi
    grimblast
  ];

  # waybar
  programs.waybar = {
    enable = true;
    systemd.enable = false;
    settings = [
      {
        layer = "top";
        position = "top";
        modules-left = [
          "wlr/workspaces"
          # TODO causing problem
          # https://github.com/Alexays/Waybar/issues/1968
          # "wlr/taskbar"
        ];
        modules-center = [
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
          # TODO causing problem
          # https://github.com/Alexays/Waybar/issues/1968
          # on-click = "activate";
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
          format-wifi = "{essid} 󰖩";
          format-ethernet = "{ifname} 󰈀";
          format-disconnected = ""; # An empty format will hide the module.
          tooltip-format = "{ifname} via {gwaddr}";
          tooltip-format-wifi = "{essid} ({signalStrength}%) 󰖩";
          tooltip-format-ethernet = "{ipaddr}/{cidr} 󰈀";
        };
        "pulseaudio" = {
          format = "{volume}% {icon}";
          format-bluetooth = "{volume}% 󰂯{icon}";
          format-muted = "󰖁";
          format-icons = {
            default = ["󰕿" "󰖀" "󰕾"];
          };
          on-click = "volumectl toggle";
          on-scroll-up = "volumectl up";
          on-scroll-down = "volumectl down";
        };
        "wireplumber" = {
          format = "{volume}% {icon}";
          format-muted = "󰖁";
          format-icons = ["󰕿" "󰖀" "󰕾"];
          on-click = "volumectl toggle";
          on-scroll-up = "volumectl up";
          on-scroll-down = "volumectl down";
        };
        "backlight" = {
          format = "{percent}% {icon}";
          format-icons = [
            "󰃚"
            "󰃛"
            "󰃜"
            "󰃝"
            "󰃞"
            "󰃟"
            "󰃠"
          ];
          on-scroll-up = "lightctl up";
          on-scroll-down = "lightctl down";
        };
        "battery" = {
          interval = 60;
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{capacity}% {icon}";
          format-icons = [
            "󰂎"
            "󰁺"
            "󰁻"
            "󰁼"
            "󰁽"
            "󰁾"
            "󰁿"
            "󰂀"
            "󰂁"
            "󰂂"
            "󰁹"
          ];
        };
        "clock" = {
          format = "{:%Y-%m-%d %H:%M} 󰥔";
        };
        "tray" = {
          spacing = 5;
        };
      }
    ];
  };
  xdg.configFile."waybar/style.css".source = buildScss "waybar";

  # grimblast
  home.sessionVariables = {
    XDG_SCREENSHOTS_DIR = "${config.xdg.userDirs.pictures}/Screenshots";
  };

  # wofi
  xdg.configFile."wofi/config".source = ./wofi.conf;
  xdg.configFile."wofi/style.css".source = buildScss "wofi";

  # dunst
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

  # swaylock
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

  # swayidle
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

  # hyprpaper
  xdg.configFile."hypr/hyprpaper.conf".text = ''
    preload = ${wallPaperLight}
    preload = ${wallPaperDark}

    wallpaper = , ${wallPaperLight}
  '';
}
