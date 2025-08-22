{
  osConfig,
  config,
  lib,
  pkgs,
  ...
}:
let
  volumeUp = [
    "qs"
    "-c"
    "DankMaterialShell"
    "ipc"
    "call"
    "audio"
    "increment"
    "3"
  ];
  volumeDown = [
    "qs"
    "-c"
    "DankMaterialShell"
    "ipc"
    "call"
    "audio"
    "decrement"
    "3"
  ];
  volumeMute = [
    "qs"
    "-c"
    "DankMaterialShell"
    "ipc"
    "call"
    "audio"
    "mute"
  ];
  volumeMicMute = [
    "qs"
    "-c"
    "DankMaterialShell"
    "ipc"
    "call"
    "audio"
    "micmute"
  ];
  lightUp = [
    "qs"
    "-c"
    "DankMaterialShell"
    "ipc"
    "call"
    "brightness"
    "increment"
    "5"
    ""
  ];
  lightDown = [
    "qs"
    "-c"
    "DankMaterialShell"
    "ipc"
    "call"
    "brightness"
    "decrement"
    "5"
    ""
  ];
in
lib.mkMerge [
  {
    programs.niri = {
      inherit (osConfig.programs.niri) package;
      settings =
        let
          # css named colors
          # https://developer.mozilla.org/en-US/docs/Web/CSS/named-color
          mainColor = "cornflowerblue";
          inactiveColor = "gray";
          shadowColor = "#00000050";
          shadow = {
            enable = true;
            color = shadowColor;
            inactive-color = shadowColor;
            draw-behind-window = true;
            softness = 8;
            offset = {
              x = 0;
              y = 0;
            };
          };
          windowCornerRadius = 8.0;
        in
        {
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
            mouse = {
            };
            warp-mouse-to-focus.enable = true;
            focus-follows-mouse = {
              enable = true;
              max-scroll-amount = "0%";
            };
            workspace-auto-back-and-forth = true;
          };
          layout = {
            gaps = 8.0;
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
              width = 2;
              active.color = mainColor;
              inactive.color = inactiveColor;
            };
            border = {
              enable = false;
              width = 2;
              active.color = mainColor;
              inactive.color = inactiveColor;
            };
            struts = { };
            tab-indicator = {
              place-within-column = true;
              active.color = mainColor;
              inactive.color = inactiveColor;
              width = 6;
              corner-radius = 3;
              gaps-between-tabs = 8;
              length.total-proportion = 0.5;
            };
            inherit shadow;
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
              matches = [
                {
                  app-id = "^Waydroid$";
                }
              ];
              default-column-width = {
                proportion = 1.0;
              };
            }
            {
              matches = [
                {
                  title = "^Picture in picture$";
                }
              ];
              open-floating = true;
            }
            {
              geometry-corner-radius = {
                bottom-left = windowCornerRadius;
                bottom-right = windowCornerRadius;
                top-left = windowCornerRadius;
                top-right = windowCornerRadius;
              };
              clip-to-geometry = true;
            }
            {
              matches = [
                {
                  app-id = "^chromium-browser$";
                }
              ];
              geometry-corner-radius = {
                bottom-left = windowCornerRadius;
                bottom-right = windowCornerRadius;
                top-left = 16.0;
                top-right = 16.0;
              };
            }
          ];
          layer-rules = [
            {
              matches = [
                { namespace = "^waybar$"; }
              ];
              inherit shadow;
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
                # overview
                "Mod+O".action.toggle-overview = [ ];
                # show help
                "Mod+Shift+Slash".action.show-hotkey-overlay = [ ];
                # terminal, app launcher, screen locker, ...
                "Mod+Return".action.spawn = [ "alacritty" ];
                "Mod+D".action.spawn = [
                  "qs"
                  "-c"
                  "DankMaterialShell"
                  "ipc"
                  "call"
                  "spotlight"
                  "toggle"
                ];
                "Mod+L".action.spawn = [
                  "loginctl"
                  "lock-session"
                ];
                "Mod+V".action.spawn = [
                  "qs"
                  "-c"
                  "DankMaterialShell"
                  "ipc"
                  "call"
                  "clipboard"
                  "toggle"
                ];
                # volume keys
                "XF86AudioRaiseVolume" = {
                  allow-when-locked = true;
                  action.spawn = volumeUp;
                  # action = spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+";
                };
                "XF86AudioLowerVolume" = {
                  allow-when-locked = true;
                  action.spawn = volumeDown;
                  # action = spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1-";
                };
                "XF86AudioMute" = {
                  allow-when-locked = true;
                  action.spawn = volumeMute;
                  # action = spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle";
                };
                "XF86AudioMicMute" = {
                  allow-when-locked = true;
                  action.spawn = volumeMicMute;
                };
                # brightness keys
                "XF86MonBrightnessUp" = {
                  allow-when-locked = true;
                  action.spawn = lightUp;
                };
                "XF86MonBrightnessDown" = {
                  allow-when-locked = true;
                  action.spawn = lightDown;
                };
                # quit windnow
                "Mod+Q".action.close-window = [ ];
                "Mod+MouseMiddle".action.close-window = [ ];
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
                "Mod+T".action.toggle-column-tabbed-display = [ ];
                # preset size
                "Mod+R".action.switch-preset-column-width = [ ];
                "Mod+Shift+R".action.reset-window-height = [ ];
                "Mod+M".action.maximize-column = [ ];
                "Mod+Shift+M".action.fullscreen-window = [ ];
                "Mod+Ctrl+M".action.toggle-windowed-fullscreen = [ ];
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
                # floating
                "Mod+BackSlash".action.switch-focus-between-floating-and-tiling = [ ];
                "Mod+Shift+BackSlash".action.toggle-window-floating = [ ];
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
          xwayland-satellite = {
            enable = true;
            path = lib.getExe pkgs.xwayland-satellite-unstable;
          };
          environment = lib.mkMerge [
            (lib.mkIf osConfig.networking.fw-proxy.enable osConfig.networking.fw-proxy.environment)
          ];
        };
    };

    # tools
    home.packages = with pkgs; [
      xwayland-satellite-unstable
    ];
  }

  # shell
  {
    programs.dankMaterialShell = {
      enable = true;
      enableSystemd = true;
    };
    home.packages = with pkgs; [
      dgop
      gammastep
      brightnessctl
    ];

    home.global-persistence.directories = [
      ".config/DankMaterialShell"
      ".local/state/DankMaterialSmhell"
    ];
  }

  # swayidle
  {
    # TODO add swayidle-locked back
    # systemd.user.services.swayidle-locked = {
    #   Unit = {
    #     ConditionEnvironment = [
    #       "WAYLAND_DISPLAY"
    #       "XDG_SEAT"
    #     ];
    #     PartOf = [ "graphical-session.target" ];
    #     BindsTo = [ "swaylock.service" ];
    #     After = [
    #       "swaylock.service"
    #       "graphical-session.target"
    #     ];
    #   };
    #   Service = {
    #     ExecStart = lib.getExe (
    #       pkgs.writeShellApplication {
    #         name = "swayidle-locked";
    #         runtimeInputs = [
    #           config.programs.niri.package
    #           config.services.swayidle.package
    #         ];
    #         text = ''
    #           exec swayidle -d -w -S "$XDG_SEAT" timeout 10 "niri msg action power-off-monitors"
    #         '';
    #       }
    #     );
    #   };
    # };

    services.swayidle =
      let
        qsLock = lib.escapeShellArgs [
          "${config.programs.quickshell.package}/bin/qs"
          "--config"
          "DankMaterialShell"
          "ipc"
          "call"
          "lock"
          "lock"
        ];
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
          "60"
        ]; # enable debug output
        events = [
          {
            event = "before-sleep";
            command = qsLock;
          }
          {
            event = "lock";
            command = qsLock;
          }
          {
            event = "unlock";
            command = qsLock;
          }
        ];
        timeouts = [
          {
            timeout = 300;
            command = qsLock;
          }
        ];
      };
    systemd.user.services.swayidle.Unit = {
      ConditionEnvironment = lib.mkForce [
        "XDG_SEAT"
        "WAYLAND_DISPLAY"
      ];
      After = [ "graphical-session.target" ];
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

  # wluma
  {
    services.wluma = {
      enable = true;
      systemd = {
        enable = true;
        target = "niri.service";
      };
    };
  }

  # osd
  {
    systemd.user.services.wvkbd = {
      Unit = {
        Description = "On-screen keyboard for wlroots";
        ConditionEnvironment = [
          "WAYLAND_DISPLAY"
        ];
        After = [ "niri.service" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart =
          let
            wvkbdDeamon = pkgs.writeShellApplication {
              name = "wvkbd-daemon";
              runtimeInputs = with pkgs; [
                wvkbd
                clickclack
                config.programs.niri.package
              ];
              text = ''
                cd "$RUNTIME_DIRECTORY"
                rm --force pressed
                mkfifo pressed
                wvkbd-mobintl --hidden -o >pressed &
                wvkbd_pid="$!"
                clickclack -V <pressed &
                clickclack_pid="$!"

                state_file="$RUNTIME_DIRECTORY/state"
                new_state_file="$RUNTIME_DIRECTORY/state.new"
                echo "hidden" >"$state_file"
                # transition_delay_ms=50

                function hide_keyboard {
                  echo "hide keyboard..."
                  echo "hidden" >"$new_state_file"
                  # niri msg action do-screen-transition --delay-ms "$transition_delay_ms"
                  kill -USR1 "$wvkbd_pid"
                  mv --force "$new_state_file" "$state_file"
                  echo "keyboard hidden"
                }
                function show_keyboard {
                  echo "show keyboard..."
                  echo "shown" >"$new_state_file"
                  # niri msg action do-screen-transition --delay-ms "$transition_delay_ms"
                  kill -USR2 "$wvkbd_pid"
                  mv --force "$new_state_file" "$state_file"
                  echo "keyboard shown"
                }

                trap "hide_keyboard" SIGUSR1
                trap "show_keyboard" SIGUSR2

                # https://stackoverflow.com/questions/55866583/wait-exits-after-trap
                function loop_wait {
                  while wait "$1"; [ "$?" -ge 128 ]; do
                    echo 'finished wait'
                  done
                }
                loop_wait "$wvkbd_pid"
                loop_wait "$clickclack_pid"
              '';
            };
          in
          lib.getExe wvkbdDeamon;
        Restart = "on-failure";
        RuntimeDirectory = "wvkbd";
      };
      Install = {
        WantedBy = lib.mkForce [ "niri.service" ];
      };
    };
  }
]
