{
  osConfig,
  config,
  lib,
  pkgs,
  ...
}:
let

  buildScss =
    name:
    pkgs.runCommand "${name}.css" {
      src = ./_styles;
      nativeBuildInputs = with pkgs; [ sass ];
    } "sass $src/${name}.scss $out";

  # configFile = pkgs.substituteAll {
  #   src = ./config.kdl;
  #   inherit (cfg) extraConfig;
  # };
  # validatedConfigFile = pkgs.runCommand "config.kdl" {
  #   nativeBuildInputs = with pkgs; [
  #     niri
  #   ];
  # } ''
  #   cp "${configFile}" "$out"
  #   niri validate --config="$out"
  # '';

  proxyCfg = osConfig.networking.fw-proxy;
  variables = lib.optionalAttrs proxyCfg.enable proxyCfg.environment // {
    # extra env variables
    DISPLAY = ":1"; # xwayland-satellite
  };
  mkVariableConfig = name: value: ''${name} "${value}"'';
  proxyConfigBlock = ''
    environment {
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList mkVariableConfig variables)}
    }
  '';

in
{
  config = {
    programs.niri = {
      inherit (osConfig.programs.niri) package;
      config =
        builtins.readFile ./config.kdl
        + ''
          // extra configurations
          ${proxyConfigBlock}
        '';
    };

    # tools
    home.packages = with pkgs; [
      avizo
    ];

    # waybar
    programs.waybar = {
      enable = true;
      systemd = {
        enable = true;
        target = "niri.service";
      };
      settings = [
        {
          layer = "top";
          position = "top";
          modules-left = [
            # "wlr/workspaces" # not working with niri
            "wlr/taskbar"
          ];
          modules-center = [ "clock" ];
          modules-right = [
            "tray"
            "network"
            "backlight"
            # "pulseaudio"
            "wireplumber"
            "battery"
          ];
          "wlr/workspaces" = {
            format = "{name}";
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
              default = [
                "󰕿"
                "󰖀"
                "󰕾"
              ];
            };
            on-click = "volumectl toggle-mute";
            on-scroll-up = "volumectl up";
            on-scroll-down = "volumectl down";
          };
          "wireplumber" = {
            format = "{volume}% {icon}";
            format-muted = "󰖁";
            format-icons = [
              "󰕿"
              "󰖀"
              "󰕾"
            ];
            on-click = "volumectl toggle-mute";
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
    systemd.user.services.waybar.Unit.After = [ "niri.service" ];
    xdg.configFile."waybar/style.css".source = buildScss "waybar";

    # xwayland
    systemd.user.services.xwayland-satellite = {
      Unit = {
        BindsTo = [ "niri.service" ];
        After = [ "niri.service" ];
        Requires = [ "niri.service" ];
      };
      Install = {
        WantedBy = [ "niri.service" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${lib.getExe pkgs.xwayland-satellite} :1";
        NotifyAccess = "all";
        StandardOutput = "journal";
      };
    };

    # fuzzel
    programs.fuzzel = {
      enable = true;
      settings =
        {
        };
    };

    # mako
    services.mako = {
      enable = true;
    };

    # swaylock
    programs.swaylock = {
      enable = true;
      package = pkgs.swaylock-effects;
      settings = {
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
    };

    # swayidle
    services.swayidle =
      let
        swaylock = "${lib.getExe config.programs.swaylock.package}";
      in
      {
        enable = true;
        systemdTarget = "niri.service";
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
        timeouts =
          let
            screenTimeout = 300;
            graceDelay = config.programs.swaylock.settings.grace;
          in
          [
            {
              timeout = screenTimeout;
              command = swaylock;
            }
            {
              timeout = screenTimeout + graceDelay;
              command = "niri msg action power-off-monitors";
            }
          ];
      };
    systemd.user.services.swayidle.Unit.After = [ "niri.service" ];
  };
}
