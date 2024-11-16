{
  osConfig,
  config,
  lib,
  pkgs,
  ...
}:
let

  buildScss =
    path:
    pkgs.runCommand "${lib.replaceStrings [ "/" ] [ "-" ] path}.css" {
      src = ./_styles;
      nativeBuildInputs = with pkgs; [ sass ];
    } "sass $src/${path}.scss $out";

  toggleDarkMode = pkgs.writeShellApplication {
    name = "niri-toggle-dark-mode";
    runtimeInputs = [
      config.programs.niri.package
      config.services.darkman.package
    ];
    text = ''
      niri msg action do-screen-transition --delay-ms 500
      darkman toggle
    '';
  };
in
lib.mkMerge [
  {
    programs.niri = {
      inherit (osConfig.programs.niri) package;
      settings = {
        input = {
          keyboard = {
            xkb = {
              layout = "us";
            };
          };
          touchpad = {
            tap = true;
            natural-scroll = true;
            dwt = true; # disable touchpad while typing
            dwtp = true; # disable touchpad while the trackpoint is in use
          };
          mouse =
            {
            };
          warp-mouse-to-focus = true;
          focus-follows-mouse = {
            enable = true;
            max-scroll-amount = "0%";
          };
        };
        layout = {
          gaps = 8;
          center-focused-column = "never";
          preset-column-widths = [
            { proportion = 1.0 / 3.0; }
            { proportion = 1.0 / 2.0; }
            { proportion = 2.0 / 3.0; }
          ];
          default-column-width = {
            proportion = 1.0 / 2.0;
          };
          focus-ring = {
            enable = true;
            width = 4;
            active.color = "#7fc8ff";
            inactive.color = "#505050";
          };
          border = {
            enable = false;
            width = 4;
            active.color = "#ffc87f";
            inactive.color = "#505050";
          };
          struts = { };
        };
        cursor = {
          theme = "Adwaita";
        };
        spawn-at-startup = [ ];
        prefer-no-csd = true;
        screenshot-path = "~/Data/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
        animations = {
          enable = true;
          # all default
        };
        window-rules = [
          {
            matches = [
              {
                app-id = "^org\.wezfurlong\.wezterm$";
              }
            ];
            default-column-width = { };
          }
          {
            geometry-corner-radius =
              let
                radius = 12.0;
              in
              {
                bottom-left = radius;
                bottom-right = radius;
                top-left = radius;
                top-right = radius;
              };
            clip-to-geometry = true;
          }
        ];
        binds =
          let
            modMove = "Shift";
            modMonitor = "Ctrl";
            keyUp = "P";
            keyDown = "N";
            keyLeft = "B";
            keyRight = "F";
            keyWorkspaceUp = "W";
            keyWorkspaceDown = "S";
            directions = {
              left = {
                keys = [
                  "Left"
                  keyLeft
                  "WheelScrollLeft"
                ];
                windowTerm = "column";
              };
              down = {
                keys = [
                  "Down"
                  keyDown
                ];
                windowTerm = "window";
              };
              up = {
                keys = [
                  "Up"
                  keyUp
                ];
                windowTerm = "window";
              };
              right = {
                keys = [
                  "Right"
                  keyRight
                  "WheelScrollRight"
                ];
                windowTerm = "column";
              };
            };
            workspaceDirections = {
              up = {
                keys = [
                  "Page_Up"
                  keyWorkspaceUp
                  "WheelScrollUp"
                ];
              };
              down = {
                keys = [
                  "Page_Down"
                  keyWorkspaceDown
                  "WheelScrollDown"
                ];
              };
            };
            workspaceIndices = lib.range 1 9;
            isWheelKey = lib.hasPrefix "Wheel";
            wheelCooldownMs = 100;

            windowBindings = lib.mkMerge (
              lib.concatLists (
                lib.mapAttrsToList (
                  direction: cfg:
                  (lib.lists.map (
                    key:
                    let
                      cooldown-ms = lib.mkIf (isWheelKey key) wheelCooldownMs;
                    in
                    {
                      "Mod+${key}" = {
                        action."focus-${cfg.windowTerm}-${direction}" = [ ];
                        inherit cooldown-ms;
                      };
                      "Mod+${modMove}+${key}" = {
                        action."move-${cfg.windowTerm}-${direction}" = [ ];
                        inherit cooldown-ms;
                      };
                      "Mod+${modMonitor}+${key}" = {
                        action."focus-monitor-${direction}" = [ ];
                        inherit cooldown-ms;
                      };
                      "Mod+${modMove}+${modMonitor}+${key}" = {
                        action."move-column-to-monitor-${direction}" = [ ];
                        inherit cooldown-ms;
                      };
                    }
                  ) cfg.keys)
                ) directions
              )
            );
            workspaceBindings = lib.mkMerge (
              lib.concatLists (
                lib.mapAttrsToList (
                  direction: cfg:
                  (lib.lists.map (
                    key:
                    let
                      cooldown-ms = lib.mkIf (isWheelKey key) wheelCooldownMs;
                    in
                    {
                      "Mod+${key}" = {
                        action."focus-workspace-${direction}" = [ ];
                        inherit cooldown-ms;
                      };
                      "Mod+${modMove}+${key}" = {
                        action."move-column-to-workspace-${direction}" = [ ];
                        inherit cooldown-ms;
                      };
                      "Mod+Ctrl+${key}" = {
                        action."move-workspace-${direction}" = [ ];
                        inherit cooldown-ms;
                      };
                    }
                  ) cfg.keys)
                ) workspaceDirections
              )
            );
            indexedWorkspaceBindings = lib.mkMerge (
              lib.map (index: {
                "Mod+${toString index}" = {
                  action.focus-workspace = [ index ];
                };
                "Mod+${modMove}+${toString index}" = {
                  action.move-column-to-workspace = [ index ];
                };
              }) workspaceIndices
            );
            specialBindings = {
              # show help
              "Mod+Shift+Slash".action.show-hotkey-overlay = [ ];
              # terminal, app launcher, screen locker, ...
              "Mod+Return".action.spawn = [ "alacritty" ];
              "Mod+D".action.spawn = [ "fuzzel" ];
              "Mod+L".action.spawn = [
                "loginctl"
                "lock-session"
              ];
              "Mod+V".action.spawn = [ "cliphist-fuzzel" ];
              # volume keys
              "XF86AudioRaiseVolume" = {
                allow-when-locked = true;
                action.spawn = [
                  "volumectl"
                  "up"
                ];
                # action = spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+";
              };
              "XF86AudioLowerVolume" = {
                allow-when-locked = true;
                action.spawn = [
                  "volumectl"
                  "down"
                ];
                # action = spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1-";
              };
              "XF86AudioMute" = {
                allow-when-locked = true;
                action.spawn = [
                  "volumectl"
                  "toggle-mute"
                ];
                # action = spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle";
              };
              "XF86AudioMicMute" = {
                allow-when-locked = true;
                action.spawn = [
                  "wpctl"
                  "set-mute"
                  "@DEFAULT_AUDIO_SOURCE@"
                  "toggle"
                ];
              };
              # brightness keys
              "XF86MonBrightnessUp" = {
                allow-when-locked = true;
                action.spawn = [
                  "lightctl"
                  "up"
                ];
              };
              "XF86MonBrightnessDown" = {
                allow-when-locked = true;
                action.spawn = [
                  "lightctl"
                  "down"
                ];
              };
              # quit windnow
              "Mod+Q".action.close-window = [ ];
              # first and last
              "Mod+A".action.focus-column-first = [ ];
              "Mod+E".action.focus-column-last = [ ];
              "Mod+${modMove}+A".action.move-column-to-first = [ ];
              "Mod+${modMove}+E".action.move-column-to-last = [ ];
              # previous workspace
              "Mod+Tab".action.focus-workspace-previous = [ ];
              # consume and expel
              "Mod+Comma".action.consume-window-into-column = [ ];
              "Mod+Period".action.expel-window-from-column = [ ];
              "Mod+BracketLeft".action.consume-or-expel-window-left = [ ];
              "Mod+BracketRight".action.consume-or-expel-window-right = [ ];
              # preset size
              "Mod+R".action.switch-preset-column-width = [ ];
              "Mod+Shift+R".action.reset-window-height = [ ];
              "Mod+M".action.maximize-column = [ ];
              "Mod+Shift+M".action.fullscreen-window = [ ];
              # center column
              "Mod+C".action.center-column = [ ];
              # manual size
              "Mod+Minus".action.set-column-width = [ "-10%" ];
              "Mod+Equal".action.set-column-width = [ "+10%" ];
              "Mod+Shift+Minus".action.set-window-height = [ "-10%" ];
              "Mod+Shift+Equal".action.set-window-height = [ "+10%" ];
              # screenshot
              "Print".action.screenshot = [ ];
              "Ctrl+Print".action.screenshot-screen = [ ];
              "Alt+Print".action.screenshot-window = [ ];
              # quit
              "Mod+Ctrl+E".action.quit = [ ];
            };
          in
          lib.mkMerge [
            specialBindings
            workspaceBindings
            indexedWorkspaceBindings
            windowBindings
          ];
        environment = lib.mkMerge [
          {
            DISPLAY = ":1"; # xwayland-satellite
          }
          (lib.mkIf osConfig.networking.fw-proxy.enable osConfig.networking.fw-proxy.environment)
        ];
      };
    };

    # tools
    home.packages = with pkgs; [
      pavucontrol
      avizo
      (pkgs.writeShellApplication {
        name = "cliphist-fuzzel";
        runtimeInputs = with pkgs; [
          wl-clipboard
        ];
        text = ''
          cliphist list | fuzzel --dmenu | cliphist decode | wl-copy
        '';
      })
    ];
  }

  # bar
  {
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
            "niri/workspaces"
            "wlr/taskbar"
          ];
          modules-center = [ "clock" ];
          modules-right = [
            "tray"
            "custom/fprintd"
            "custom/darkman"
            "network"
            "backlight"
            # "pulseaudio"
            "wireplumber"
            "battery"
          ];
          "niri/workspaces" = {
            # "current-only" = true;
            # "all-outputs" = true;
          };
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
            format-ethernet = "󰈀";
            format-disconnected = ""; # an empty format will hide the module.
            tooltip-format = "{ifname} via {gwaddr}";
            tooltip-format-wifi = "{essid} ({signalStrength}%) 󰖩";
            tooltip-format-ethernet = "{ipaddr}/{cidr} 󰈀";
            on-click = "alacritty --command nmtui";
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
            on-click = "pavucontrol";
            on-click-right = "volumectl toggle-mute";
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
            on-click = "pavucontrol";
            on-click-right = "volumectl toggle-mute";
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
            on-click = "gnome-power-statistics";
          };
          "clock" = {
            format = "{:%Y-%m-%d %a. %H:%M}";
          };
          "tray" = {
            spacing = 5;
          };
          "custom/fprintd" =
            let
              signal = 10;
            in
            {
              exec = lib.getExe (
                pkgs.writeShellApplication {
                  name = "waybar-fprintd";
                  runtimeInputs = [
                    osConfig.systemd.package
                  ];
                  text = ''
                    if [ -f /run/fprintd-blocker ]; then
                      echo '{"text": "Disabled", "alt": "fprintd-disabled", "class": "disabled"}'
                    else
                      echo '{"text": "Enabled", "alt": "fprintd-enabled", "class": "enabled"}'
                    fi
                  '';
                }
              );
              exec-if = lib.getExe (
                pkgs.writeShellApplication {
                  name = "waybar-fprintd-if";
                  runtimeInputs = [
                    osConfig.systemd.package
                  ];
                  text = ''
                    systemctl list-unit-files fprintd.service &>/dev/null
                  '';
                }
              );
              return-type = "json";
              format = "{icon}";
              interval = 3;
              format-icons = {
                "fprintd-enabled" = "󰈷";
                "fprintd-disabled" = "󰺱";
              };
              inherit signal;
              on-click = lib.getExe (
                pkgs.writeShellApplication {
                  name = "toggle-fprintd";
                  runtimeInputs = [
                    osConfig.systemd.package
                    pkgs.procps
                  ];
                  text = ''
                    if [ -f /run/fprintd-blocker ]; then
                      systemctl stop fprintd-blocker
                    else
                      systemctl start fprintd-blocker
                    fi
                    pkill "-SIGRTMIN+${toString signal}" waybar
                  '';
                }
              );
            };
          "custom/darkman" =
            let
              signal = 11;
            in
            {
              exec = lib.getExe (
                pkgs.writeShellApplication {
                  name = "waybar-darkman";
                  runtimeInputs = [
                    config.services.darkman.package
                  ];
                  text = ''
                    mode="$(darkman get)"
                    if [ "$mode" != light ] && [ "$mode" != dark ]; then
                      mode="unknown"
                    fi
                    echo '{"text": "'"$mode"'", "alt": "'"$mode"'", "class": "'"$mode"'"}'
                  '';
                }
              );
              exec-if = lib.getExe (
                pkgs.writeShellApplication {
                  name = "waybar-darkman-if";
                  runtimeInputs = [
                    osConfig.systemd.package
                  ];
                  text = ''
                    systemctl --user is-active darkman
                  '';
                }
              );
              return-type = "json";
              format = "{icon}";
              interval = 3;
              format-icons = {
                "light" = "󰖙";
                "dark" = "󰖔";
                "unknown" = "󰔎";
              };
              inherit signal;
              on-click = lib.getExe (
                pkgs.writeShellApplication {
                  name = "toggle-fprintd";
                  runtimeInputs = [
                    pkgs.procps
                  ];
                  text = ''
                    "${lib.getExe toggleDarkMode}"
                    pkill "-SIGRTMIN+${toString signal}" waybar
                  '';
                }
              );
            };
        }
      ];
    };
    systemd.user.services.waybar.Unit.After = [ "niri.service" ];
    xdg.configFile."waybar/style-light.css".source = buildScss "waybar/light";
    xdg.configFile."waybar/style-dark.css".source = buildScss "waybar/dark";
    xdg.configFile."waybar/style.css".source = config.xdg.configFile."waybar/style-light.css".source;
  }

  # xwayland
  {
    systemd.user.services.xwayland-satellite = {
      Unit = {
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        Requisite = [ "graphical-session.target" ];
        OnFailure = [ "xwayland-satellite-failure-report.service" ];
      };
      Install = {
        WantedBy = [ "niri.service" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${lib.getExe pkgs.xwayland-satellite} :1";
        NotifyAccess = "all";
        StandardOutput = "journal";
        Restart = "on-failure";
      };
    };
    systemd.user.services.xwayland-satellite-failure-report = {
      Service = {
        Type = "oneshot";
        ExecStart = lib.escapeShellArgs [
          (lib.getExe pkgs.libnotify)
          "--urgency=critical"
          "xwayland-satellite"
          "Crashed and restarting..."
        ];
      };
    };
  }

  # fuzzel
  {
    programs.fuzzel = {
      enable = true;
      settings = {
        colors = {
          background = "282a36ff";
          text = "f8f8f2ff";
          match = "8be9fdff";
          selection-match = "8be9fdff";
          selection = "44475add";
          selection-text = "f8f8f2ff";
          border = "bd93f9ff";
        };
      };
    };
  }

  # mako
  {
    services.mako = {
      enable = true;
      borderRadius = 8;
      borderSize = 2;
      backgroundColor = "#000000FF";
      extraConfig = ''
        [urgency=low]
        border-color=#66ffccff

        [urgency=normal]
        border-color=#7fc8ffff

        [urgency=critical]
        border-color=#ff3300ff
      '';
    };
  }

  # swaylcok and swayidle
  {
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

    systemd.user.services.swaylock = {
      Unit = {
        ConditionEnvironment = [
          "WAYLAND_DISPLAY"
        ];
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        Wants = [ "swayidle-locked.service" ];
      };
      Service = {
        Type = "forking";
        ExecStartPre = "${lib.getExe config.programs.niri.package} msg action do-screen-transition --delay-ms 1000";
        ExecStart = "${lib.getExe config.programs.swaylock.package}";
        KillSignal = "SIGUSR1";
      };
    };
    systemd.user.services.swayidle-locked = {
      Unit = {
        ConditionEnvironment = [
          "WAYLAND_DISPLAY"
          "XDG_SEAT"
        ];
        PartOf = [ "graphical-session.target" ];
        BindsTo = [ "swaylock.service" ];
        After = [
          "swaylock.service"
          "graphical-session.target"
        ];
      };
      Service = {
        ExecStart = lib.getExe (
          pkgs.writeShellApplication {
            name = "swayidle-locked";
            runtimeInputs = [
              config.programs.niri.package
              config.services.swayidle.package
            ];
            text = ''
              exec swayidle -d -w -S "$XDG_SEAT" \
                timeout 10 "niri msg action power-off-monitors"
            '';
          }
        );
      };
    };

    services.swayidle =
      let
        systemctl = "${osConfig.systemd.package}/bin/systemctl";
      in
      {
        enable = true;
        systemdTarget = "niri.service";
        extraArgs = [
          "-d" # debug output
          "-w" # wait for command
          "-S"
          "$XDG_SEAT"
          "idlehint"
          "300"
        ]; # enable debug output
        events = [
          {
            event = "before-sleep";
            command = "${systemctl} --user start swaylock";
          }
          {
            event = "lock";
            command = "${systemctl} --user start swaylock";
          }
          {
            event = "unlock";
            command = "${systemctl} --user stop swaylock";
          }
        ];
        timeouts = [
          {
            timeout = 300;
            command = "${systemctl} --user start swaylock";
          }
        ];
      };
    systemd.user.services.swayidle.Unit = {
      ConditionEnvironment = lib.mkForce [
        "XDG_SEAT"
        "WAYLAND_DISPLAY"
      ];
      After = [ "niri.service" ];
    };
  }

  # kanshi
  {
    home.packages = with pkgs; [
      wdisplays
      wlr-randr
    ];
    services.kanshi = {
      enable = true;
      systemdTarget = "niri.service";
    };
  }

  # cliphist
  {
    services.cliphist = {
      enable = true;
      systemdTarget = "niri.service";
    };
    systemd.user.services.cliphist = {
      Unit = {
        ConditionEnvironment = [
          "WAYLAND_DISPLAY"
        ];
        After = "niri.service";
      };
    };
  }

  # swaybg
  (
    let
      lightBg = "${pkgs.nixos-artwork.wallpapers.nineish}/share/backgrounds/nixos/nix-wallpaper-nineish.png";
      darkBg = "${pkgs.nixos-artwork.wallpapers.nineish-dark-gray}/share/backgrounds/nixos/nix-wallpaper-nineish-dark-gray.png";
    in
    {
      systemd.user.services.swaybg = {
        Unit = {
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
          Requisite = [ "graphical-session.target" ];
        };
        Install = {
          WantedBy = [ "niri.service" ];
        };
        Service = {
          Restart = "on-failure";
          ExecStart = lib.escapeShellArgs [
            (lib.getExe pkgs.swaybg)
            "--mode"
            "fill"
            "--image"
            "%h/.config/swaybg/image"
          ];
        };
      };
      systemd.user.tmpfiles.rules = [
        # link theme if not exists
        "L %h/.config/swaybg/image - - - - ${lightBg}"
      ];
      services.darkman =
        let
          swaybgSwitch = pkgs.writeShellApplication {
            name = "darkman-switch-swaybg";
            text = ''
              mode="$1"
              if ! systemctl --user is-active swaybg; then
                echo "swaybg is not active"
                exit 1
              fi
              if [ "$mode" = light ]; then
                ln --force --symbolic --verbose "${lightBg}" "$HOME/.config/swaybg/image"
              elif [ "$mode" = dark ]; then
                ln --force --symbolic --verbose "${darkBg}" "$HOME/.config/swaybg/image"
              else
                echo "invalid mode: $mode"
                exit 1
              fi
              systemctl --user restart swaybg
            '';
          };
        in
        {
          lightModeScripts.swaybg = "${lib.getExe swaybgSwitch} light";
          darkModeScripts.swaybg = "${lib.getExe swaybgSwitch} dark";
        };
    }
  )

  # input dialog
  {
    programs.niri.settings.binds."Mod+Shift+Return".action.spawn = [ "input-dialog" ];
    home.packages = [
      (pkgs.writeShellApplication {
        name = "input-dialog";
        runtimeInputs = [
          config.services.emacs.package
          pkgs.wl-clipboard
        ];
        text = ''
          file="$(mktemp -t input-dialog.XXXXXX)"
          function cleanup {
            rm -f "$file"
          }
          trap cleanup EXIT
          emacsclient --create-frame "$file"
          wl-copy --foreground --trim-newline --type text/plain <"$file"
        '';
      })
    ];
  }
]
