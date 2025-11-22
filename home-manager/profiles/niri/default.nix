{
  osConfig,
  config,
  lib,
  pkgs,
  ...
}:
let
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
          screenshot-path = "${config.xdg.userDirs.pictures}/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
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
      pwvucontrol
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
  (
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
      defaultWallpaper = pkgs.fetchurl {
        url = "https://i.imgur.com/RjK9cTr.png";
        hash = "sha256-ZciNE8e3G3/qSxvmN/qUd3Qd2zngD3B8/kl5iZ/r8ss=";
      };
      specialSettings = {
        general.avatarImage = "${config.home.homeDirectory}/.face";
        hooks.darkModeChange = "${lib.getExe toggleDarkMode} $1";
        screenRecorder.directory = "${config.xdg.userDirs.videos}/Recordings";
        wallpaper = {
          defaultWallpaper = "${defaultWallpaper}";
          directory = "${config.xdg.userDirs.pictures}/Wallpapers";
        };
      };
      syncSettings = pkgs.writeShellApplication {
        name = "noctalia-sync-settings";
        runtimeInputs = with pkgs; [
          jq
        ];
        text = ''
          if [ "$PRJ_ROOT" != "$NH_FLAKE" ]; then
            echo "Error: not in nh flake directory"
            exit 1
          fi
          path="home-manager/profiles/niri/noctalia-base-settings.json"
          full_path="$PRJ_ROOT/home-manager/profiles/niri/noctalia-base-settings.json"
          echo "writing to '$full_path'..."
          jq 'del(
            ${lib.concatMapAttrsStringSep ",\n  " (name: _value: ".${name}") (
              osConfig.lib.self.flattenTree {
                separator = ".";
                mapper = x: "\"${x}\"";
              } specialSettings
            )}
          )' ~/.config/noctalia/gui-settings.json >"$full_path"
          nix fmt

          echo "git diff..."
          git diff -- "$path"

          echo "checking leak path..."
          jq 'pick(.. | select(type == "string" and contains("/")))' "$full_path"
        '';
      };
    in
    {
      programs.noctalia-shell = {
        enable = true;
        systemd.enable = true;
        settings = lib.recursiveUpdate (builtins.fromJSON (builtins.readFile ./noctalia-base-settings.json)) specialSettings;
      };
      systemd.user.services.emacs =
        let
          inherit (osConfig.networking) fw-proxy;
        in
        {
          Service.Environment = lib.mkIf fw-proxy.enable fw-proxy.stringEnvironment;
        };
      xdg.configFile."noctalia/settings.json".force = true;

      passthru.noctalia = {
        inherit syncSettings;
      };

      home.packages = with pkgs; [
        mpv
        matugen # TODO remove this workaround

        syncSettings
      ];
    }
  )

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

  # swayidle
  {
    services.swayidle = {
      enable = true;
      events = [
        {
          event = "before-sleep";
          command = lib.escapeShellArgs lockScreen;
        }
        {
          event = "lock";
          command = lib.escapeShellArgs lockScreen;
        }
      ];
      timeouts = [
        {
          timeout = 300;
          command = lib.escapeShellArgs lockScreen;
        }
        {
          timeout = 330;
          command = "${lib.getExe config.programs.niri.package} msg action power-off-monitors";
        }
      ];
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
