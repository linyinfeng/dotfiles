{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.niri;
  spawn = command: "spawn ${lib.concatMapStringsSep " " (s: "\"${s}\"") command}";
  restoreWorking = pkgs.writeShellApplication {
    name = "niri-restore-working";
    text = ''
      script="$HOME/Local/scripts/niri-restore-working.sh"
      if [ -f "$script" ]; then
        exec sh "$script"
      fi
    '';
  };
in
{
  options.programs = {
    niri = {
      prefer-no-csd = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Prefer non-client-side-decorated windows.";
      };
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
  };
  config = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (
    lib.mkMerge [
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

            ${lib.optionalString cfg.prefer-no-csd "prefer-no-csd"}

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
                proportion 1.0
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
              ${lib.optionalString config.home.env.proxy.enable (
                lib.concatMapAttrsStringSep "\n  " (
                  name: value: "${name} \"${value}\""
                ) config.home.env.proxy.environment
              )}
            }

            binds {
              ${lib.concatStringsSep "\n  " cfg.binds}
            }

            switch-events {
              tablet-mode-on  { spawn "sh" "-c" "gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled true"; }
              tablet-mode-off { spawn "sh" "-c" "gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled false"; }
            }

            // blur effects suggested by
            // https://docs.noctalia.dev/v5/compositor-settings/niri/
            window-rule {
              draw-border-with-background false
              background-effect {
                blur true
                xray true
              }
            }
            window-rule {
              match is-floating=true
              background-effect {
                xray false
              }
            }
            layer-rule {
              match namespace="^noctalia-(bar-[^\"]+|notification|dock|panel|attached-panel|osd)$"
              background-effect {
                xray false
                // blur false
              }
            }

            window-rule {
              match app-id="dev.noctalia.Noctalia"
              open-floating true
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
              match app-id="^google-chrome$"
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
              match namespace="^noctalia-notifications-"
              match namespace="^notifications$"
              block-out-from "screencast"
            }
            layer-rule {
              match namespace="^noctalia-overview-"
              place-within-backdrop true
            }
            layer-rule {
              match namespace="^noctalia-backdrop$"
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

            // restore working environment
            spawn-at-startup "niri-restore-working"

            // noctalia shell
            spawn-at-startup "noctalia"
            include "noctalia.kdl"
          '';
        systemd.user.tmpfiles.rules = [
          # create an empty file if not exists
          "f %h/.config/niri/noctalia.kdl - - - -"
        ];
        home.packages = [
          restoreWorking
        ];
        programs.niri.binds =
          let
            # Niri spells the wheel chords as `WheelScroll*` and takes an action
            # as a KDL node, so the shared keymap is translated, not rendered
            # verbatim.
            niriKey =
              key:
              lib.replaceStrings
                [
                  "WheelLeft"
                  "WheelRight"
                  "WheelUp"
                  "WheelDown"
                ]
                [
                  "WheelScrollLeft"
                  "WheelScrollRight"
                  "WheelScrollUp"
                  "WheelScrollDown"
                ]
                key;
            kdlString = value: "\"${lib.replaceStrings [ "\\" "\"" ] [ "\\\\" "\\\"" ] value}\"";
            niriActions = {
              # focus
              "window-focus-left" = "focus-column-left";
              "window-focus-right" = "focus-column-right";
              "window-focus-up" = "focus-window-up";
              "window-focus-down" = "focus-window-down";
              "window-focus-switch-floating" = "switch-focus-between-floating-and-tiling";
              "column-focus-first" = "focus-column-first";
              "column-focus-last" = "focus-column-last";
              "output-focus-left" = "focus-monitor-left";
              "output-focus-right" = "focus-monitor-right";
              "output-focus-up" = "focus-monitor-up";
              "output-focus-down" = "focus-monitor-down";

              # move and resize
              "column-move-left" = "move-column-left";
              "column-move-right" = "move-column-right";
              "window-move-up" = "move-window-up";
              "window-move-down" = "move-window-down";
              "column-move-to-first" = "move-column-to-first";
              "column-move-to-last" = "move-column-to-last";
              "column-move-to-output-left" = "move-column-to-monitor-left";
              "column-move-to-output-right" = "move-column-to-monitor-right";
              "column-move-to-output-up" = "move-column-to-monitor-up";
              "column-move-to-output-down" = "move-column-to-monitor-down";
              "column-center" = "center-column";
              "window-consume-left" = "consume-window-into-column";
              "window-consume-or-expel-left" = "consume-or-expel-window-left";
              "window-consume-or-expel-right" = "consume-or-expel-window-right";
              "window-cycle-primary-extent" = "switch-preset-column-width";
              "window-reset-height" = "reset-window-height";
              "window-modify-primary-extent:-0.1" = "set-column-width \"-10%\"";
              "window-modify-primary-extent:0.1" = "set-column-width \"+10%\"";
              "window-modify-secondary-extent:-0.1" = "set-window-height \"-10%\"";
              "window-modify-secondary-extent:0.1" = "set-window-height \"+10%\"";

              # workspaces
              "workspace-previous" = "focus-workspace-up";
              "workspace-next" = "focus-workspace-down";
              "column-move-to-workspace-previous" = "move-column-to-workspace-up";
              "column-move-to-workspace-next" = "move-column-to-workspace-down";
              "workspace-move-up" = "move-workspace-up";
              "workspace-move-down" = "move-workspace-down";

              # windows
              "window-close" = "close-window";
              "window-toggle-floating" = "toggle-window-floating";
              "window-toggle-fullscreen" = "fullscreen-window";
              "window-toggle-maximize" = "maximize-column";
              "window-toggle-maximize-to-edges" = "maximize-window-to-edges";
              "column-toggle-tabbed" = "toggle-column-tabbed-display";

              # overview, help and session
              "overview-toggle" = "toggle-overview";
              "cheatsheet-toggle" = "show-hotkey-overlay";
              "shortcuts-inhibit-toggle" = "toggle-keyboard-shortcuts-inhibit";

              # screenshots
              "screenshot-region" = "screenshot show-pointer=false";
              "screenshot-output" = "screenshot-screen show-pointer=false";
              "screenshot-output-copy" = "screenshot-screen show-pointer=false write-to-disk=false";
              "screenshot-window" = "screenshot-window";
              "screenshot-window-copy" = "screenshot-window write-to-disk=false";
            };
            niriAction =
              action:
              if lib.hasPrefix "workspace-switch:" action then
                "focus-workspace ${lib.removePrefix "workspace-switch:" action}"
              else if lib.hasPrefix "column-move-to-workspace:" action then
                "move-column-to-workspace ${lib.removePrefix "column-move-to-workspace:" action}"
              else
                niriActions.${action} or (throw "window-manager: no niri action for `${action}`");
            renderBind =
              bind:
              let
                action =
                  if bind.spawn != null then
                    "spawn ${lib.concatMapStringsSep " " kdlString bind.spawn}"
                  else
                    niriAction bind.action;
                properties = lib.concatStringsSep " " (
                  lib.optional (bind.title != null) "hotkey-overlay-title=${kdlString bind.title}"
                  ++ lib.optional (bind.cooldownMs != null) "cooldown-ms=${toString bind.cooldownMs}"
                  ++ lib.optional (!bind.repeat) "repeat=false"
                  ++ lib.optional bind.allowWhenLocked "allow-when-locked=true"
                );
              in
              "${niriKey bind.key}${lib.optionalString (properties != "") " ${properties}"} { ${action}; }";
          in
          map renderBind config.programs.windowManager.binds;
      }

      # shared with the other compositors
      {
        world.profiles.window-manager.enable = true;
      }

      # noctalia (niri side)
      {
        programs.noctalia.themeModeChangedCommands = [
          "niri msg action do-screen-transition --delay-ms 500"
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
              After = [ "niri.service" ];
              PartOf = [ "niri.service" ];
              ConditionEnvironment = [ "WAYLAND_DISPLAY" ];
            };
            Service = {
              ExecStart = lib.getExe' nirius "niriusd";
              Type = "simple";
              Restart = "on-failure";
            };
            Install = {
              WantedBy = [ "niri.service" ];
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
              config.home.env.systemdPackage
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
              After = [ "graphical-session.target" ];
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
              WantedBy = [ "niri.service" ];
            };
          };
        }
      )

      # system76-niri-scheduler
      {
        services.system76-scheduler-niri.enable = true;
      }

      # touch
      (
        let
          lisgd = pkgs.lisgd.override {
            conf = ./lisgd-config.h;
          };
        in
        {
          systemd.user.services.lisgd = {
            Unit = {
              Description = "Libinput Synthetic Gesture Daemon";
              After = [ "graphical-session.target" ];
              PartOf = [ "graphical-session.target" ];
              ConditionPathExists = [ "/dev/input/touchscreen" ];
            };
            Install = {
              # The gestures run `niri msg`, so only start them in a niri session.
              WantedBy = [ "niri.service" ];
            };
            Service = {
              ExecStart = "${lib.getExe lisgd} -v";
            };
          };
        }
      )
    ]
  );
}
