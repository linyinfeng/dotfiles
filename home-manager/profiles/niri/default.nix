{
  osConfig,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.niri;
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
  spawn = command: ''spawn ${lib.concatMapStringsSep " " (s: "\"${s}\"") command}'';
in
{
  options.programs.niri = {
    default-column-proportion = lib.mkOption {
      type = lib.types.float;
      default = 0.5;
      description = "Default proportion of new columns.";
    };
    binds = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
    };
  };
  config = lib.mkMerge [
    {
      xdg.configFile."niri/config.kdl".text =
        let
          windowCornerRadius = 8.0;
          # css named colors
          # https://developer.mozilla.org/en-US/docs/Web/CSS/named-color
          mainColor = "cornflowerblue";
          inactiveColor = "gray";
          shadowColor = "#00000050";
          shadow = ''
            shadow {
              on
              offset x=0 y=0
              softness 8
              spread 5
              draw-behind-window true
              color "${shadowColor}"
              inactive-color "${shadowColor}"
            }
          '';
        in
        ''
          input {
            keyboard {
              xkb {
                layout "us"
              }
              repeat-delay 600
              repeat-rate 25
              track-layout "global"
            }
            touchpad {
              tap
              dwt
              dwtp
              natural-scroll
            }
            warp-mouse-to-focus
            focus-follows-mouse max-scroll-amount="0%"
            workspace-auto-back-and-forth
          }

          screenshot-path "${config.xdg.userDirs.pictures}/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

          prefer-no-csd

          layout {
            gaps 8
            struts {
              left 0
              right 0
              top 0
              bottom 0
            }
            focus-ring {
              width 2
              active-color "${mainColor}"
              inactive-color "${inactiveColor}"
            }
            border { off; }
            ${shadow}
            tab-indicator {
              place-within-column
              gap 5
              width 6
              length total-proportion=0.5
              position "left"
              gaps-between-tabs 8
              corner-radius 3
              active-color "${mainColor}"
              inactive-color "${inactiveColor}"
            }
            default-column-width { proportion ${toString cfg.default-column-proportion}; }
            preset-column-widths {
              proportion 0.333333
              proportion 0.5
              proportion 0.666667
            }
            center-focused-column "never"
          }

          cursor {
            xcursor-theme "Adwaita"
            xcursor-size 24
          }

          recent-windows {
            highlight {
              padding 30
              corner-radius ${toString windowCornerRadius}
            }

            binds {
              Alt+Tab         { next-window; }
              Alt+Shift+Tab   { previous-window; }
              Alt+grave       { next-window     filter="app-id"; }
              Alt+Shift+grave { previous-window filter="app-id"; }
            }
          }

          environment {
            ${lib.optionalString osConfig.networking.fw-proxy.enable (
              lib.concatMapAttrsStringSep "\n  " (
                name: value: "${name} \"${value}\""
              ) osConfig.networking.fw-proxy.environment
            )}
          }

          binds {
            ${lib.concatStringsSep "\n  " cfg.binds}
          }

          switch-events {
            tablet-mode-on  { spawn "sh" "-c" "gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled true"; }
            tablet-mode-off { spawn "sh" "-c" "gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled false"; }
          }

          window-rule {
            geometry-corner-radius ${toString windowCornerRadius}
            clip-to-geometry true
          }
          window-rule {
            match app-id="^Alacritty$"
            opacity 0.9
          }
          window-rule {
            match app-id="^org.wezfurlong.wezterm$"
            default-column-width { }
          }
          window-rule {
            match title="^Picture in picture$"
            match title="^Picture-in-Picture$"
            open-floating true
            default-floating-position x=32 y=32 relative-to="bottom-right"
          }
          window-rule {
            match app-id="^chromium-browser$"
            geometry-corner-radius 16 16 ${toString windowCornerRadius} ${toString windowCornerRadius}
          }
          window-rule {
            match is-floating=false app-id="^Waydroid$"
            match is-floating=false app-id="^com.moonlight_stream.Moonlight$"
            open-maximized-to-edges true
            default-column-width { proportion 1.0; }
          }
          window-rule {
            match app-id="^QQ$"
            match app-id="^org.telegram.desktop$"
            block-out-from "screencast"
          }
          layer-rule {
            match namespace="^waybar$"
            ${shadow}
          }
          layer-rule {
            match namespace="^noctalia-notifications-"
            match namespace="^notifications$"
            block-out-from "screencast"
          }
          layer-rule {
            match namespace="^noctalia-overview-"
            place-within-backdrop true
          }
          xwayland-satellite {
            path "${lib.getExe pkgs.xwayland-satellite}";
          }

          // https://docs.noctalia.dev/getting-started/compositor-settings/
          debug {
            // allows notification actions and window activation from noctalia
            honor-xdg-activation-with-invalid-serial
          }

          include "noctalia.kdl"
        '';
      systemd.user.tmpfiles.rules = [
        # create an empty file if not exists
        "f %h/.config/niri/noctalia.kdl - - - -"
      ];
      programs.niri.binds =
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

          windowBindings = lib.mapAttrsToList (
            direction: cfg:
            (lib.lists.map (
              key:
              let
                cooldown = if (isWheelKey key) then "cooldown-ms=${toString wheelCooldownMs} " else "";
              in
              [
                "Mod+${key} ${cooldown}{ focus-${cfg.windowTerm}-${direction}; }"
                "Mod+${modMove}+${key} ${cooldown}{ move-${cfg.windowTerm}-${direction}; }"
                "Mod+${modMonitor}+${key} ${cooldown}{ focus-monitor-${direction}; }"
                "Mod+${modMove}+${modMonitor}+${key} ${cooldown}{ move-column-to-monitor-${direction}; }"
              ]
            ) cfg.keys)
          ) directions;
          workspaceBindings = lib.mapAttrsToList (
            direction: cfg:
            (lib.lists.map (
              key:
              let
                cooldown = if (isWheelKey key) then "cooldown-ms=${toString wheelCooldownMs} " else "";
              in
              [
                "Mod+${key} ${cooldown}{ focus-workspace-${direction}; }"
                "Mod+${modMove}+${key} ${cooldown}{ move-column-to-workspace-${direction}; }"
                "Mod+Ctrl+${key} ${cooldown}{ move-workspace-${direction}; }"
              ]
            ) cfg.keys)
          ) workspaceDirections;
          indexedWorkspaceBindings = lib.map (index: [
            "Mod+${toString index} { focus-workspace ${toString index}; }"
            "Mod+${modMove}+${toString index} { move-column-to-workspace ${toString index}; }"
          ]) workspaceIndices;
          specialBindings = [
            # overview
            "Mod+O { toggle-overview; }"
            # show help
            "Mod+Shift+Slash { show-hotkey-overlay; }"
            # terminal, app launcher, screen locker, ...
            "Mod+Return repeat=false { ${spawn [ "alacritty" ]}; }"
            "Mod+D hotkey-overlay-title=\"Toggle launcher\" repeat=false { ${spawn launcherToggle}; }"
            "Mod+L hotkey-overlay-title=\"Lock screen\"     { ${spawn lockScreen}; }"
            # volume keys
            "XF86AudioRaiseVolume allow-when-locked=true { ${spawn volumeUp}; }"
            "XF86AudioLowerVolume allow-when-locked=true { ${spawn volumeDown}; }"
            "XF86AudioMute        allow-when-locked=true { ${spawn volumeMute}; }"
            "XF86AudioMicMute     allow-when-locked=true { ${spawn volumeMicMute}; }"
            # brightness keys
            "XF86MonBrightnessUp   allow-when-locked=true { ${spawn lightUp}; }"
            "XF86MonBrightnessDown allow-when-locked=true { ${spawn lightDown}; }"
            # quit window
            "Mod+Q { close-window; }"
            "Mod+MouseMiddle { close-window; }"
            # first and last
            "Mod+A { focus-column-first; }"
            "Mod+E { focus-column-last; }"
            "Mod+${modMove}+A { move-column-to-first; }"
            "Mod+${modMove}+E { move-column-to-last; }"
            # consume and expel
            "Mod+Comma  { consume-window-into-column; }"
            "Mod+Period { expel-window-from-column; }"
            "Mod+BracketLeft  { consume-or-expel-window-left; }"
            "Mod+BracketRight { consume-or-expel-window-right; }"
            "Mod+T { toggle-column-tabbed-display; }"
            # preset size
            "Mod+R { switch-preset-column-width; }"
            "Mod+Shift+R { reset-window-height; }"
            "Mod+M { maximize-column; }"
            "Mod+Shift+M { fullscreen-window; }"
            "Mod+Ctrl+M { maximize-window-to-edges; }"
            # center column
            "Mod+C { center-column; }"
            # manual size
            "Mod+Minus       { set-column-width \"-10%\"; }"
            "Mod+Equal       { set-column-width \"+10%\"; }"
            "Mod+Shift+Minus { set-window-height \"-10%\"; }"
            "Mod+Shift+Equal { set-window-height \"+10%\"; }"
            # screenshot
            "Print            { screenshot show-pointer=false; }"
            "Ctrl+Print       { screenshot-screen show-pointer=false; }"
            "Ctrl+Shift+Print { screenshot-screen show-pointer=false write-to-disk=false; }"
            "Alt+Print        { screenshot-window; }"
            "Alt+Shift+Print  { screenshot-window write-to-disk=false; }"
            # floating
            "Mod+BackSlash       { switch-focus-between-floating-and-tiling; }"
            "Mod+Shift+BackSlash { toggle-window-floating; }"
            # inhibit
            "Mod+Escape { toggle-keyboard-shortcuts-inhibit; }"
            # quit
            "Mod+Ctrl+E { quit; }"
          ];
        in
        lib.flatten [
          specialBindings
          workspaceBindings
          indexedWorkspaceBindings
          windowBindings
        ];

      wayland.systemd.target = "niri.service";
    }

    # noctalia
    (
      let
        toggleDarkMode = pkgs.writeShellApplication {
          name = "noctalia-toggle-dark-mode";
          runtimeInputs = [
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
          url = "https://i.imgur.com/JjM8xZf.jpeg";
          hash = "sha256-67Igunje3W8U6kH87F8y/Fl/6kFUv3tD9xWAkH1/Gfw=";
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

            echo "checking path leaking..."
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
        home.file.".cache/noctalia/wallpapers.json" = {
          text = builtins.toJSON {
            defaultWallpaper = "${defaultWallpaper}";
          };
          force = true;
        };

        passthru.noctalia = {
          inherit syncSettings;
        };

        home.packages = with pkgs; [
          mpv
          matugen # TODO remove this workaround
          pwvucontrol

          syncSettings
        ];

        xdg.configFile."alacritty/alacritty.toml".force = true; # allow noctalia to manage alacritty theme
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
        home.packages = [
          nirius
        ];
        programs.niri.binds = [
          "Mod+Ctrl+BackSpace hotkey-overlay-title=\"Toggle follow mode\" repeat=false { ${
            spawn [
              "nirius"
              "toggle-follow-mode"
            ]
          }; }"
        ];
      }
    )

    # swayidle
    {
      services.swayidle = {
        enable = true;
        events = {
          before-sleep = lib.escapeShellArgs lockScreen;
          lock = lib.escapeShellArgs lockScreen;
        };
        timeouts = [
          {
            timeout = 300;
            command = lib.escapeShellArgs lockScreen;
          }
          {
            timeout = 330;
            command = "${lib.getExe osConfig.programs.niri.package} msg action power-off-monitors";
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

    # wl-mirror
    {
      home.packages =
        let
          inherit (pkgs) wl-mirror;
          mirror = pkgs.writeShellApplication {
            name = "mirror";
            runtimeInputs = [ wl-mirror ];
            text = ''
              wl-mirror --backend screencopy-dmabuf --fullscreen-output "$2" "$1"
            '';
          };
        in
        [
          wl-mirror
          mirror
        ];
    }

    # hexexcute
    (lib.mkIf (pkgs ? hexecute) {
      home.packages = with pkgs; [
        hexecute
      ];
      programs.niri.binds = [
        "Mod+X { ${
          spawn [
            "hexecute"
          ]
        }; }"
      ];
      home.global-persistence.directories = [
        ".config/hexecute"
      ];
    })

    # osd
    (
      let
        wvkbd = pkgs.wvkbd.overrideAttrs (oldAttrs: {
          makeFlags = (oldAttrs.makeFlags or [ ]) ++ [
            "LAYOUT=deskintl"
          ];
        });
        wvkbdToggle = pkgs.writeShellApplication {
          name = "wvkbd-toggle";
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
          '';
        };
      in
      {
        home.packages = [ wvkbdToggle ];
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
                  runtimeInputs = [
                    wvkbd
                    pkgs.clickclack
                  ];
                  text = ''
                    cd "$RUNTIME_DIRECTORY"
                    rm --force pressed
                    mkfifo pressed
                    wvkbd-deskintl --hidden -o >pressed &
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
                      kill -USR1 "$wvkbd_pid"
                      mv --force "$new_state_file" "$state_file"
                      echo "keyboard hidden"
                    }
                    function show_keyboard {
                      echo "show keyboard..."
                      echo "shown" >"$new_state_file"
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
    )
  ];
}
