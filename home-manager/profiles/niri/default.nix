{
  osConfig,
  config,
  lib,
  pkgs,
  ...
}:
let
  json = pkgs.formats.json { };
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
  volumeUp = [
    "swayosd-client"
    "--output-volume"
    "raise"
  ];
  volumeDown = [
    "swayosd-client"
    "--output-volume"
    "lower"
  ];
  volumeMute = [
    "swayosd-client"
    "--output-volume"
    "mute-toggle"
  ];
  volumeMicMute = [
    "swayosd-client"
    "--input-volume"
    "mute-toggle"
  ];
  lightUp = [
    "swayosd-client"
    "--brightness"
    "raise"
  ];
  lightDown = [
    "swayosd-client"
    "--brightness"
    "lower"
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
                {
                  app-id = "^com.moonlight_stream.Moonlight$";
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
            {
              matches = [ { namespace = "^notifications$"; } ];
              block-out-from = "screencast";
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
                "Mod+D".action.spawn = [ "fuzzel" ];
                "Mod+L".action.spawn = [
                  "loginctl"
                  "lock-session"
                ];
                "Mod+V".action.spawn = [ "cliphist-fuzzel" ];
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
      pavucontrol
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

  # waybar
  {
    programs.waybar = {
      enable = true;
      systemd = {
        enable = true;
        target = "niri.service";
      };
      settings = [
        {
          id = "status";
          name = "bar-status";

          layer = "top";
          position = "top";
          modules-left = [
            "custom/overview"
            "custom/launcher"
            "niri/workspaces"
            "wlr/taskbar"
          ];
          modules-center = [ "clock" ];
          modules-right = [
            "tray"
            "custom/separator"

            "privacy"
            "custom/fprintd"
            "idle_inhibitor"

            "custom/darkman"
            "backlight"

            "network"
            "wireplumber"
            "custom/osd"
            "systemd-failed-units"
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
            icon-size = 16;
            all-outputs = false;
            on-click = "activate";
            on-click-middle = "close";
          };
          "network" = {
            format = "󰛳";
            format-wifi = "󰖩";
            format-ethernet = "󰈀";
            format-disconnected = ""; # an empty format will hide the module.
            tooltip-format = "{ifname} via {gwaddr}";
            tooltip-format-wifi = "{essid} ({signalStrength}%) 󰖩";
            tooltip-format-ethernet = "{ipaddr}/{cidr} 󰈀";
            on-click = "alacritty --command nmtui";
          };
          "wireplumber" = {
            format = "{icon}";
            tooltip-format = "{volume}% {icon}";
            format-muted = "󰖁";
            format-icons = [
              "󰕿"
              "󰖀"
              "󰕾"
            ];
            on-click = "pavucontrol";
            on-click-right = lib.escapeShellArgs volumeMute;
            on-scroll-up = lib.escapeShellArgs volumeUp;
            on-scroll-down = lib.escapeShellArgs volumeDown;
          };
          "backlight" = {
            format = "{icon}";
            tooltip-format = "{percent}% {icon}";
            format-icons = [
              "󰃚"
              "󰃛"
              "󰃜"
              "󰃝"
              "󰃞"
              "󰃟"
              "󰃠"
            ];
            on-scroll-up = lib.escapeShellArgs lightUp;
            on-scroll-down = lib.escapeShellArgs lightDown;
          };
          "battery" = {
            interval = 60;
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{icon} {capacity}%";
            format-discharging = "{icon} {capacity}% ({power:.1f}W)";
            tooltip-format = "{timeTo}";
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
            format = "{:%H:%M}";
            tooltip-format = "<tt>{:%Y-%m-%d %a. %H:%M} \n{calendar}</tt>";
            calendar = {
              mode = "month";
              mode-mon-col = 3;
              weeks-pos = "right";
              on-scroll = 1;
              format = {
                months = "<span color='#ffead3'><b>{}</b></span>";
                days = "<span color='#ecc6d9'><b>{}</b></span>";
                weeks = "<span color='#99ffdd'><b>W{}</b></span>";
                weekdays = "<span color='#ffcc66'><b>{}</b></span>";
                today = "<span color='#ff6699'><b><u>{}</u></b></span>";
              };
            };
            actions = {
              on-click-right = "mode";
              on-scroll-up = "shift_up";
              on-scroll-down = "shift_down";
            };
          };
          "tray" = {
            spacing = 12;
            icon-size = 16;
          };
          "custom/overview" = {
            format = "󰮔";
            inverval = "once";
            tooltip-format = "Overview";
            on-click = "niri msg action toggle-overview";
          };
          "custom/launcher" = {
            format = "󰍜";
            inverval = "once";
            tooltip-format = "Launcher";
            on-click = "fuzzel";
          };
          "custom/separator" = {
            format = "|";
            interval = "once";
            tooltip = false;
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
                  name = "toggle-darkman";
                  runtimeInputs = [
                    pkgs.procps
                  ];
                  text = ''
                    "${lib.getExe toggleDarkMode}"
                    pkill "-SIGRTMIN+${toString signal}" waybar
                  '';
                }
              );
              on-click-right =
                let
                  changeWlsunsetMode = pkgs.writeShellApplication {
                    name = "change-wlsunset-mode";
                    runtimeInputs = [
                      config.programs.niri.package
                      osConfig.systemd.package
                    ];
                    text = ''
                      niri msg action do-screen-transition --delay-ms 100
                      systemctl --user kill wlsunset.service --signal=USR1
                    '';
                  };
                in
                lib.getExe changeWlsunsetMode;
            };
          "custom/osd" =
            let
              signal = 12;
            in
            {
              exec = lib.getExe (
                pkgs.writeShellApplication {
                  name = "waybar-osd";
                  text = ''
                    wvkbd_state_file="$XDG_RUNTIME_DIR/wvkbd/state"
                    state="$(cat "$wvkbd_state_file")"
                    if [ "$state" = "shown" ]; then
                      echo '{"text": "Shown", "alt": "osd-shown", "class": "shown"}'
                    elif [ "$state" = "hidden" ]; then
                      echo '{"text": "Hidden", "alt": "osd-hidden", "class": "hidden"}'
                    else
                      echo '{"text": "Unknown", "alt": "osd-unknown", "class": "unknown"}'
                    fi
                  '';
                }
              );
              exec-if = lib.getExe (
                pkgs.writeShellApplication {
                  name = "waybar-wvkbd-if";
                  text = ''
                    wvkbd_state_file="$XDG_RUNTIME_DIR/wvkbd/state"
                    [ -f "$wvkbd_state_file" ]
                  '';
                }
              );
              return-type = "json";
              format = "{icon}";
              interval = 3;
              format-icons = {
                "osd-shown" = "󰌌";
                "osd-hidden" = "󰌐";
              };
              inherit signal;
              on-click = lib.getExe (
                pkgs.writeShellApplication {
                  name = "toggle-wvkbd";
                  runtimeInputs = [
                    osConfig.systemd.package
                    pkgs.procps
                  ];
                  text = ''
                    wvkbd_state_file="$XDG_RUNTIME_DIR/wvkbd/state"
                    state="$(cat "$wvkbd_state_file")"
                    if [ "$state" = "shown" ]; then
                      systemctl --user kill --kill-whom=main --signal=USR1 wvkbd.service
                    elif [ "$state" = "hidden" ]; then
                      systemctl --user kill --kill-whom=main --signal=USR2 wvkbd.service
                    fi
                    pkill "-SIGRTMIN+${toString signal}" waybar
                  '';
                }
              );
            };
          "privacy" = {
            icon-spacing = 12;
            icon-size = 16;
            modules = [
              {
                type = "screenshare";
                tooltip = true;
              }
              {
                type = "audio-in";
                tooltip = true;
              }
              {
                type = "audio-out";
                tooltip = true;
              }
            ];
          };
          "idle_inhibitor" = {
            format = "{icon}";
            format-icons = {
              "activated" = "";
              "deactivated" = "";
            };
          };
          "systemd-failed-units" = {
            hide-on-ok = true;
            format = "{nr_failed} ⚠";
            system = true;
            user = true;
          };
        }
      ];
    };
    systemd.user.services.waybar.Unit.After = [ "graphical-session.target" ];
    xdg.configFile."waybar/style-light.css".source = buildScss "waybar/light";
    xdg.configFile."waybar/style-dark.css".source = buildScss "waybar/dark";
    xdg.configFile."waybar/style.css".source = config.xdg.configFile."waybar/style-light.css".source;
    home.packages = with pkgs; [
      nerdfix
    ];
  }

  # waybar in overview
  (
    let
      package = pkgs.waybar;
      waybarConfig = [
        {
          id = "tasks";
          name = "bar-tasks";
          layer = "top";
          position = "bottom";
          exclusive = false;
          start_hidden = true;
          on-sigusr2 = "show";
          on-sigusr1 = "hide";
          modules-center = [ "cffi/niri-taskbar" ];
          "cffi/niri-taskbar" = {
            module_path = "${pkgs.nur.repos.linyinfeng.niri-taskbar}/lib/libniri_taskbar.so";
          };
        }
      ];
      configFile = json.generate "waybar-overview-config.json" waybarConfig;
    in
    {
      systemd.user.services.waybar-overview = {
        Unit = {
          After = [ "niri.service" ];
          ConditionEnvironment = [ "WAYLAND_DISPLAY" ];
          PartOf = [ "graphical-session.target" ];
          X-Restart-Triggers = [
            "${configFile}"
          ];
        };
        Service = {
          ExecStart = "${lib.getExe package} --config ${configFile}";
          Restart = "on-failure";
        };
        # disabled
        # Install = {
        #   WantedBy = [ "niri.service" ];
        # };
      };
    }
  )

  # overview watcher
  {
    systemd.user.services.niri-overview-watcher = {
      Unit = {
        After = [
          "niri.service"
          "waybar-overview.service"
        ];
        ConditionEnvironment = [ "WAYLAND_DISPLAY" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = lib.getExe (
          pkgs.writeShellApplication {
            name = "niri-overview-watcher";
            runtimeInputs = [
              config.programs.niri.package
              pkgs.jq
              osConfig.systemd.package
            ];
            text = ''
              function overview_events {
                niri msg --json event-stream |\
                  stdbuf -o0 jq '.OverviewOpenedOrClosed.is_open | select (. != null)'
              }
              function handle_events {
                while read -r line; do
                  if [ "$line" = "true" ]; then
                    echo "overview open..."
                    systemctl --user kill --signal=USR2 waybar-overview.service || true
                  elif [ "$line" = "false" ]; then
                    echo "overview close..."
                    systemctl --user kill --signal=USR1 waybar-overview.service || true
                  else
                    echo "unknown overview open state event: $line"
                  fi
                done
              }
              overview_events | handle_events
            '';
          }
        );
        Restart = "on-failure";
      };
      Install = {
        WantedBy = [ "niri.service" ];
      };
    };
  }

  # swayosd
  {
    services.swayosd.enable = true;
    systemd.user.services.swayosd.Install.WantedBy = lib.mkForce [ "niri.service" ];
  }

  # fuzzel
  {
    programs.fuzzel = {
      enable = true;
      settings = {
        main = {
          icon-theme = "Adwaita";
        };
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
      settings = {
        border-radius = 8;
        border-size = 2;
        background-color = "#000000FF";
        "urgency=low" = {
          border-color = "#66ffccff";
        };
        "urgency=normal" = {
          border-color = "#7fc8ffff";
        };
        "urgency=critical" = {
          border-color = "#ff3300ff";
        };
      };
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

  # cliphist
  {
    services.cliphist = {
      enable = true;
      systemdTargets = [ "niri.service" ];
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

  # wlsunset
  {
    services.wlsunset = {
      enable = true;
      systemdTarget = "niri.service";
      sunrise = "6:00";
      sunset = "18:00";
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
