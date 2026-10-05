{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;

  # Actions are spelled the way Umbriel spells them
  # (https://docs.noctalia.dev/umbriel/actions/), so each compositor profile only
  # has to translate the names it does not share, and this file stays the single
  # source of truth for the keymap.
  noctaliaMsg =
    args:
    [
      "noctalia"
      "msg"
    ]
    ++ args;

  # Wheel chords fire once per scroll event, so one flick would otherwise move
  # several columns or workspaces.
  wheelCooldownMs = 100;
  mkBind =
    key: bind:
    {
      inherit key;
    }
    // lib.optionalAttrs (lib.hasInfix "Wheel" key) { cooldownMs = wheelCooldownMs; }
    // bind;

  # Only stepwise actions keep stepping while the chord is held: focus, movement,
  # workspace switching, resizing, volume and brightness. Everything else is a
  # toggle or a one-shot and takes the `repeat = false` default.
  repeating = key: bind: mkBind key (bind // { repeat = true; });

  bindType = types.submodule {
    options = {
      key = mkOption {
        type = types.str;
        description = "Key chord, e.g. `Mod+H`, `Mod+Shift+WheelUp` or `XF86AudioMute`.";
      };
      action = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Compositor action. Exactly one of `action` and `spawn` is set.";
      };
      spawn = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = "Command and arguments to launch. Exactly one of `action` and `spawn` is set.";
      };
      repeat = mkOption {
        type = types.bool;
        default = false;
        description = "Whether a held chord keeps running the action.";
      };
      allowWhenLocked = mkOption {
        type = types.bool;
        default = false;
        description = "Whether the chord is available while the session is locked.";
      };
      title = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Human-readable title for the compositor's hotkey overlay.";
      };
      cooldownMs = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        description = "Suppress repeated runs of the action for this long.";
      };
    };
  };

  # A direction's focus and move actions follow its term: columns are focused
  # and moved as a whole left and right, rows of a column up and down.
  directions = {
    left = {
      term = "column";
      keys = [
        "Left"
        "B"
        "WheelLeft"
      ];
    };
    down = {
      term = "window";
      keys = [
        "Down"
        "N"
      ];
    };
    up = {
      term = "window";
      keys = [
        "Up"
        "P"
      ];
    };
    right = {
      term = "column";
      keys = [
        "Right"
        "F"
        "WheelRight"
      ];
    };
  };

  directionBinds = lib.concatMap (
    direction:
    lib.concatMap (
      key:
      let
        term = directions.${direction}.term;
      in
      [
        (repeating "Mod+${key}" { action = "window-focus-${direction}"; })
        (repeating "Mod+Shift+${key}" { action = "${term}-move-${direction}"; })
        (repeating "Mod+Ctrl+${key}" { action = "output-focus-${direction}"; })
        (repeating "Mod+Shift+Ctrl+${key}" { action = "column-move-to-output-${direction}"; })
      ]
    ) directions.${direction}.keys
  ) (lib.attrNames directions);

  # `previous`/`next` are the workspace switch, `up`/`down` the workspace's own
  # position in the list.
  workspaceDirections = {
    up = {
      word = "previous";
      keys = [
        "Page_Up"
        "W"
        "WheelUp"
      ];
    };
    down = {
      word = "next";
      keys = [
        "Page_Down"
        "S"
        "WheelDown"
      ];
    };
  };

  workspaceBinds = lib.concatMap (
    direction:
    lib.concatMap (
      key:
      let
        word = workspaceDirections.${direction}.word;
      in
      [
        (repeating "Mod+${key}" { action = "workspace-${word}"; })
        (repeating "Mod+Shift+${key}" { action = "column-move-to-workspace-${word}"; })
        (repeating "Mod+Ctrl+${key}" { action = "workspace-move-${direction}"; })
      ]
    ) workspaceDirections.${direction}.keys
  ) (lib.attrNames workspaceDirections);

  workspaceIndexBinds = lib.concatMap (index: [
    {
      key = "Mod+${toString index}";
      action = "workspace-switch:${toString index}";
    }
    {
      key = "Mod+Shift+${toString index}";
      action = "column-move-to-workspace:${toString index}";
    }
  ]) (lib.range 1 9);

  # Binds outside the direction and workspace families.
  specialBinds = [
    # overview and help
    (mkBind "Mod+O" { action = "overview-toggle"; })
    (mkBind "Mod+Shift+Slash" { action = "cheatsheet-toggle"; })

    # applications, session and system
    (mkBind "Mod+Return" { spawn = [ "alacritty" ]; })
    (mkBind "Mod+X" { spawn = [ "hexecute" ]; })
    (mkBind "Mod+D" {
      spawn = noctaliaMsg [
        "panel-toggle"
        "launcher"
      ];
      title = "Toggle launcher";
    })
    (mkBind "Mod+L" {
      spawn = noctaliaMsg [
        "session"
        "lock"
      ];
      title = "Lock screen";
    })
    (mkBind "Mod+Ctrl+E" {
      spawn = noctaliaMsg [
        "panel-toggle"
        "session"
      ];
    })
    (mkBind "Mod+Escape" { action = "shortcuts-inhibit-toggle"; })

    # volume and brightness
    (repeating "XF86AudioRaiseVolume" {
      spawn = noctaliaMsg [ "volume-up" ];
      allowWhenLocked = true;
    })
    (repeating "XF86AudioLowerVolume" {
      spawn = noctaliaMsg [ "volume-down" ];
      allowWhenLocked = true;
    })
    (mkBind "XF86AudioMute" {
      spawn = noctaliaMsg [ "volume-mute" ];
      allowWhenLocked = true;
    })
    (mkBind "XF86AudioMicMute" {
      spawn = noctaliaMsg [ "mic-mute" ];
      allowWhenLocked = true;
    })
    (repeating "XF86MonBrightnessUp" {
      spawn = noctaliaMsg [ "brightness-up" ];
      allowWhenLocked = true;
    })
    (repeating "XF86MonBrightnessDown" {
      spawn = noctaliaMsg [ "brightness-down" ];
      allowWhenLocked = true;
    })

    # windows
    (mkBind "Mod+Q" { action = "window-close"; })
    (mkBind "Mod+MouseMiddle" { action = "window-close"; })
    (mkBind "Mod+A" { action = "column-focus-first"; })
    (mkBind "Mod+E" { action = "column-focus-last"; })
    (mkBind "Mod+Shift+A" { action = "column-move-to-first"; })
    (mkBind "Mod+Shift+E" { action = "column-move-to-last"; })
    (mkBind "Mod+BracketLeft" { action = "window-consume-or-expel-left"; })
    (mkBind "Mod+BracketRight" { action = "window-consume-or-expel-right"; })
    (mkBind "Mod+T" { action = "column-toggle-tabbed"; })
    (mkBind "Mod+R" { action = "window-cycle-primary-extent"; })
    (mkBind "Mod+Shift+R" { action = "window-reset-height"; })
    (mkBind "Mod+M" { action = "window-toggle-maximize"; })
    (mkBind "Mod+Shift+M" { action = "window-toggle-fullscreen"; })
    (mkBind "Mod+Ctrl+M" { action = "window-toggle-maximize-to-edges"; })
    (mkBind "Mod+C" { action = "column-center"; })
    (repeating "Mod+Minus" { action = "window-modify-primary-extent:-0.1"; })
    (repeating "Mod+Equal" { action = "window-modify-primary-extent:0.1"; })
    (repeating "Mod+Shift+Minus" { action = "window-modify-secondary-extent:-0.1"; })
    (repeating "Mod+Shift+Equal" { action = "window-modify-secondary-extent:0.1"; })
    (mkBind "Mod+BackSlash" { action = "window-focus-switch-floating"; })
    (mkBind "Mod+Shift+BackSlash" { action = "window-toggle-floating"; })

    # screenshots
    (mkBind "Print" { action = "screenshot-region"; })
    (mkBind "Ctrl+Print" { action = "screenshot-output"; })
    (mkBind "Ctrl+Shift+Print" { action = "screenshot-output-copy"; })
    (mkBind "Alt+Print" { action = "screenshot-window"; })
    (mkBind "Alt+Shift+Print" { action = "screenshot-window-copy"; })
  ];
in
{
  options.programs.windowManager.binds = mkOption {
    type = types.listOf bindType;
    # `assertions` only exists outside a submodule, so the cross-field check is
    # an `apply`.
    apply =
      binds:
      let
        malformed = lib.filter (bind: (bind.action != null) == (bind.spawn != null)) binds;
      in
      if malformed == [ ] then
        binds
      else
        throw "window-manager: these binds need exactly one of `action` and `spawn`: ${
          lib.concatMapStringsSep ", " (bind: bind.key) malformed
        }";
    default = specialBinds ++ workspaceBinds ++ workspaceIndexBinds ++ directionBinds;
    description = ''
      Keymap shared by the compositor profiles, which render it into their own
      keybind syntax.
    '';
  };

  config = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (
    lib.mkMerge [
      {
        home.packages = [
          # cursor theme
          pkgs.adwaita-icon-theme
        ];
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
      {
        home.packages = with pkgs; [
          linyinfeng.hexecute
        ];
        home.global-persistence.directories = [
          ".config/hexecute"
        ];
      }

      # fastfetch
      {
        home.packages = with pkgs; [
          fastfetch
        ];
      }
    ]
  );
}
