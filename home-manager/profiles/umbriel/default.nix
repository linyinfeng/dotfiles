{
  config,
  lib,
  pkgs,
  ...
}:
let
  windowManager = config.programs.windowManager;

  # Only actions Umbriel names differently, or can only run as a command, need an
  # entry; `null` leaves the chord unbound.
  actionOverrides = {
    # Umbriel has no reset for a row's extent; the full extent is the closest
    # idempotent equivalent.
    "window-reset-height" = "window-set-secondary-extent:1.0";

    # Noctalia's output policy decides save versus copy, so there is no
    # per-invocation copy.
    "screenshot-region" = {
      spawn = [
        "noctalia"
        "msg"
        "screenshot-region"
      ];
    };
    "screenshot-output" = {
      spawn = [
        "noctalia"
        "msg"
        "screenshot-fullscreen"
      ];
    };
    "screenshot-output-copy" = {
      spawn = [
        "noctalia"
        "msg"
        "screenshot-fullscreen"
      ];
    };
    # Neither Umbriel nor Noctalia captures a single window.
    "screenshot-window" = null;
    "screenshot-window-copy" = null;
  };

  bindValue =
    bind:
    let
      action =
        if bind.spawn != null then
          "spawn:${lib.concatStringsSep " " bind.spawn}"
        else
          let
            override = actionOverrides.${bind.action} or bind.action;
          in
          if lib.isString override then
            override
          else if override == null then
            null
          else
            "spawn:${lib.concatStringsSep " " override.spawn}";
      settings = {
        inherit action;
      }
      // lib.optionalAttrs (!bind.repeat) { repeat = false; }
      // lib.optionalAttrs bind.allowWhenLocked { allow_when_locked = true; }
      // lib.optionalAttrs (bind.cooldownMs != null) { cooldown_ms = bind.cooldownMs; };
    in
    if action == null then
      null
    else if lib.length (lib.attrNames settings) == 1 then
      # A bind with no options stays a plain string.
      action
    else
      settings;

  keybinds = lib.listToAttrs (
    lib.concatMap (
      bind:
      let
        value = bindValue bind;
      in
      lib.optional (value != null) (lib.nameValuePair bind.key value)
    ) windowManager.binds
  );

  # Umbriel's own bindings, which the shared keymap cannot express.
  extraKeybinds = {
    # Noctalia's window switcher replaces niri's recent-windows overlay.
    "Alt+Tab" = {
      action = "spawn:noctalia msg window-switcher hold";
      repeat = false;
    };
    # Scratchpads have no niri counterpart.
    "Mod+Space" = "scratchpad-toggle";
    "Mod+Shift+Space" = {
      action = "window-move-to-scratchpad";
      repeat = false;
    };
    "Mod+Ctrl+Space" = {
      action = "window-restore-from-scratchpad";
      repeat = false;
    };
    "Mod+Tab" = "scratchpad-focus-next";
  };

  # Mirrors the other compositor profiles where Umbriel has an equivalent.
  settings = {
    # Noctalia writes its theme into this included file.
    include.optional.files = [ "noctalia.toml" ];

    general = {
      # Let noctalia's notification actions activate their window.
      focus_on_activate = true;
      # Show the cheatsheet only on demand.
      show_cheatsheet = false;
    };

    input = {
      keyboard = {
        layout = "us";
        repeat_delay = 600;
        repeat_rate = 25;
        track_layout = "global";
      };
      touchpad = {
        tap = true;
        natural_scroll = true;
        disable_while_typing = true;
      };
      # Reveal only windows that are already fully visible.
      focus = {
        follows_mouse = true;
        follows_mouse_max_scroll = 0.0;
      };
      # Move the pointer along with keyboard-driven focus.
      cursor = {
        theme = "Adwaita";
        size = 24;
        follows_focus = true;
      };
    };

    layout = {
      gap = 8;
      extent_presets = [
        0.333333
        0.5
        0.666667
        1.0
      ];
      struts = {
        left = 0;
        right = 0;
        top = 0;
        bottom = 0;
      };
      scrolling = {
        default_extent_fraction = 0.5;
        center_focused = "never";
      };
    };

    workspaces.back_and_forth = true;

    # https://docs.noctalia.dev/compositor-settings/umbriel/
    appearance = {
      prefer_no_csd = true;
      blur = {
        enabled = true;
        optimized = true;
        passes = 3;
        radius = 3;
      };
    };

    # https://docs.noctalia.dev/compositor-settings/umbriel/
    layer_rule = [
      {
        match.namespace = "^noctalia-(bar-[^\"]+|notification|dock|panel|attached-panel|osd)$";
        blur = true;
        blur_ignore_alpha = 0.5;
        blur_optimized = false;
      }
    ];

    window_rule = [
      {
        blur = true;
        blur_optimized = true;
      }
      # Noctalia's settings window and its screencast source picker.
      {
        match.app_id = "^dev.noctalia.Noctalia$";
        default_floating = true;
        default_floating_size_px = {
          width = 1020;
          height = 900;
        };
      }
      {
        match.app_id = "^dev.noctalia.UmbrielSharePicker$";
        default_floating = true;
        default_floating_size_px = {
          width = 800;
          height = 600;
        };
      }
      # Pin noctalia's notification toasts to the bottom right.
      {
        match.title = "^notificationtoasts_.+_desktop";
        default_position = {
          x = 0;
          y = 0;
          anchor = "bottom_right";
        };
        default_focused = false;
        default_pinned = true;
      }
      {
        match.title = "^(Picture-in-Picture|Picture in picture)$";
        default_floating = true;
        default_maximize = false;
        default_position = {
          x = 20;
          y = 20;
          anchor = "bottom_right";
        };
      }
      {
        match.app_id = "^Alacritty$";
        opacity = 0.9;
      }
      {
        match.app_id = "^Waydroid$";
        default_maximize_to_edges = true;
        default_scrolling_extent = 1.0;
      }
      {
        match.app_id = "^com.moonlight_stream.Moonlight$";
        default_maximize_to_edges = true;
        default_scrolling_extent = 1.0;
      }
    ];

    keybinds = keybinds // extraKeybinds;
  }
  // lib.optionalAttrs config.home.env.proxy.enable {
    # The compositor's children need the proxy too.
    environment = config.home.env.proxy.environment;
  };
in
{
  config = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    world.profiles.window-manager.enable = true;

    programs.umbriel = {
      enable = true;
      inherit settings;
    };

    # noctalia writes to an optional include, which has to exist.
    systemd.user.tmpfiles.rules = [
      "f %h/.config/umbriel/noctalia.toml - - - -"
    ];
  };
}
