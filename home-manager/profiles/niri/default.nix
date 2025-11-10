{
  osConfig,
  config,
  lib,
  pkgs,
  ...
}:
let
  toggleDarkMode = pkgs.writeShellApplication {
    name = "noctalia-toggle-dark-mode";
    runtimeInputs = [
      config.programs.niri.package
      config.services.darkman.package
    ];
    text = ''
      if [ "$1" = "true" ]; then
        mode="dark"
      else
        mode="light"
      fi
      niri msg action do-screen-transition --delay-ms 500
      darkman set "$mode"
    '';
  };
  noctaliaIpc =
    cmd:
    [
      "noctalia-shell"
      "ipc"
      "call"
    ]
    ++ cmd;
  launcherToggle = noctaliaIpc [
    "launcher"
    "toggle"
  ];
  volumeUp = noctaliaIpc [
    "volume"
    "increase"
  ];
  volumeDown = noctaliaIpc [
    "volume"
    "decrease"
  ];
  volumeMute = noctaliaIpc [
    "volume"
    "muteOutput"
  ];
  volumeMicMute = noctaliaIpc [
    "volume"
    "muteInput"
  ];
  lightUp = noctaliaIpc [
    "brightness"
    "increase"
  ];
  lightDown = noctaliaIpc [
    "brightness"
    "decrease"
  ];
  lockScreen = noctaliaIpc [
    "lockScreen"
    "lock"
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
                "Mod+D".action.spawn = launcherToggle;
                "Mod+L".action.spawn = lockScreen;
                # volume keys
                "XF86AudioRaiseVolume" = {
                  allow-when-locked = true;
                  action.spawn = volumeUp;
                };
                "XF86AudioLowerVolume" = {
                  allow-when-locked = true;
                  action.spawn = volumeDown;
                };
                "XF86AudioMute" = {
                  allow-when-locked = true;
                  action.spawn = volumeMute;
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

    wayland.systemd.target = "niri.service";

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

  # noctalia
  {
    programs.noctalia-shell = {
      enable = true;
      systemd.enable = true;
      settings = {
        settingsVersion = 20;
        setupCompleted = true;
        ui = {
          fontDefault = "Sans Serif";
          fontFixed = "Monospace";
        };
        appLauncher = {
          useApp2Unit = true;
          terminalCommand = "alacritty --command";
          position = "top_center";
        };
        audio = {
          volumeStep = 1;
        };
        colorSchemes = {
          darkMode = false;
          useWallpaperColors = true;
        };
        bar = {
          widgets = {
            center = [
              {
                id = "Clock";
              }
              {
                id = "NotificationHistory";
                hideWhenZero = true;
                showUnreadBadge = true;
              }
            ];
            left = [
              {
                id = "ControlCenter";
                useDistroLogo = true;
              }
              {
                id = "Workspace";
              }
              {
                id = "Taskbar";
                onlyActiveWorkspaces = true;
                onlySameOutput = true;
              }
            ];
            right = [
              {
                id = "Tray";
                blacklist = [ ];
                colorizeIcons = false;
                drawerEnabled = true;
                favorites = [
                  "Fcitx"
                ];
              }
              {
                id = "WiFi";
              }
              {
                id = "Bluetooth";
              }
              {
                id = "Volume";
              }
              {
                id = "MediaMini";
                showAlbumArt = true;
                showVisualizer = true;
                visualizerType = "mirrored";
              }
              { id = "KeepAwake"; }
              { id = "DarkMode"; }
              {
                id = "Brightness";
              }
              {
                id = "Battery";
                warningThreshold = 30;
              }
            ];
          };
        };
        brightness = {
          brightnessStep = 1;
          enableDdcSupport = true;
          enforceMinimum = true;
        };
        controlCenter = {
          cards = [
            {
              enabled = true;
              id = "profile-card";
            }
            {
              enabled = true;
              id = "shortcuts-card";
            }
            {
              enabled = true;
              id = "audio-card";
            }
            {
              enabled = true;
              id = "weather-card";
            }
            {
              enabled = true;
              id = "media-sysmon-card";
            }
          ];
          shortcuts = {
            left = [
              { id = "WiFi"; }
              { id = "Bluetooth"; }
              { id = "ScreenRecorder"; }
              { id = "WallpaperSelector"; }
            ];
            right = [
              { id = "Notifications"; }
              { id = "PowerProfile"; }
              { id = "KeepAwake"; }
              { id = "NightLight"; }
            ];
          };
        };
        dock = {
          enabled = true;
          displayMode = "auto_hide";
        };
        general = {
          avatarImage = "${config.home.homeDirectory}/.face";
        };
        hooks = {
          enabled = true;
          darkModeChange = "${lib.getExe toggleDarkMode} $1";
          wallpaperChange = "";
        };
        location = {
          weatherEnabled = true;
          name = "Nanjing";
        };
        network = {
          wifiEnabled = true;
        };
        audio = {
          visualizerType = "mirrored";
          preferredPlayer = "mpv";
        };
        nightLight = {
          enabled = true;
          autoSchedule = true;
          dayTemp = "6500";
          nightTemp = "4000";
        };
        notifications = {
          enabled = true;
          location = "top";
        };
        osd = {
          enabled = true;
          location = "top_right";
          autoHideMs = 1000;
        };
        screenRecorder = {
          directory = "${config.xdg.userDirs.videos}/Recordings";
        };
        wallpaper = {
          directory = "${config.xdg.userDirs.pictures}/Wallpapers";
          recursiveSearch = true;
        };
      };
    };
    xdg.configFile."noctalia/settings.json".force = true;

    home.packages = with pkgs; [
      mpv
      app2unit
    ];
  }

  # nirius
  (
    let
      inherit (pkgs) nirius;
    in
    {
      systemd.user.services.niriusd = {
        Unit = {
          After = [ config.wayland.systemd.target ];
          PartOf = [ config.wayland.systemd.target ];
          Requires = [ config.wayland.systemd.target ];
          ConditionEnvironment = [ "WAYLAND_DISPLAY" ];
        };
        Service = {
          ExecStart = lib.getExe' nirius "niriusd";
          Type = "simple";
          Restart = "on-failure";
        };
        Install = {
          WantedBy = [ config.wayland.systemd.target ];
        };
      };
      programs.niri.settings.binds = {
        "Mod+Ctrl+BackSlash".action.spawn = [
          "nirius"
          "toggle-follow-mode"
        ];
      };
      home.packages = [
        nirius
      ];
    }
  )

  # kanshi
  {
    home.packages = with pkgs; [
      wdisplays
      wlr-randr
    ];
    services.kanshi = {
      enable = true;
    };
  }

  # wluma
  {
    services.wluma = {
      # noctalia notification for brightness change is annoying
      enable = false;
      systemd.enable = true;
    };
  }
]
