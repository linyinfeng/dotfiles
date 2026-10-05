{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.noctalia;
  themeModeChanged = pkgs.writeShellApplication {
    name = "noctalia-toggle-theme-mode-change";
    runtimeInputs = [
      config.services.darkman.package
    ];
    text = ''
      ${lib.concatStringsSep "\n" cfg.themeModeChangedCommands}
      darkman set "$NOCTALIA_THEME_MODE"
    '';
  };
  defaultWallpaper = pkgs.fetchurl {
    url = "https://i.imgur.com/JjM8xZf.jpeg";
    hash = "sha256-67Igunje3W8U6kH87F8y/Fl/6kFUv3tD9xWAkH1/Gfw=";
  };
  specialSettings = {
    dock.pinned = config.programs.desktop-files.favorites;
    hooks.theme_mode_changed = "${lib.getExe themeModeChanged} $1";
    shell.avatar_path = "${config.home.homeDirectory}/.face";
    wallpaper = {
      default.path = "${defaultWallpaper}";
      directory = "${config.xdg.userDirs.pictures}/Wallpapers";
    };
    widget.sysmon.path = config.home.global-persistence.root;
  };
  syncSettings = pkgs.writeShellApplication {
    name = "noctalia-sync-settings";
    runtimeInputs = with pkgs; [
      jq
      toml2json
    ];
    text = ''
      if [ "$PRJ_ROOT" != "$NH_FLAKE" ]; then
        echo "Error: not in nh flake directory"
        exit 1
      fi
      path="home-manager/profiles/noctalia/noctalia-base-settings.json"
      full_path="$PRJ_ROOT/home-manager/profiles/noctalia/noctalia-base-settings.json"

      tmp_dir=$(mktemp -t --directory noctalia-sync-settings.XXXXXXXXXX)
      function cleanup {
        rm -r "$tmp_dir"
      }
      trap cleanup EXIT
      noctalia config export | toml2json | jq >"$tmp_dir/current-settings.json"

      echo "writing to '$full_path'..."
      cat "$tmp_dir/current-settings.json" | jq 'del(
        ${lib.concatMapAttrsStringSep ",\n  " (name: _value: ".${name}") (
          config.lib.self.flattenTree {
            separator = ".";
            mapper = x: "\"${x}\"";
          } specialSettings
        )}
      )' >"$full_path"
      nix fmt

      echo "git diff..."
      git diff -- "$path"

      echo "checking path leaking..."
      jq 'pick(.. | select(type == "string" and contains("/")))' "$full_path"
    '';
  };
in
{
  options.programs.noctalia = {
    extraSettings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Extra settings merged into noctalia's settings, last.";
    };
    themeModeChangedCommands = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      description = "Commands run before the noctalia theme mode is applied, e.g. the compositor's screen transition.";
    };
  };

  config = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    programs.noctalia = {
      enable = true;
      systemd.enable = true;
      settings = lib.foldr lib.recursiveUpdate { } [
        (builtins.fromJSON (builtins.readFile ./noctalia-base-settings.json))
        specialSettings
        cfg.extraSettings
      ];
    };

    passthru.noctalia = {
      inherit syncSettings;
    };

    home.packages = with pkgs; [
      mpv
      matugen
      ddcutil

      syncSettings
    ];

    # allow noctalia to manage alacritty theme
    xdg.configFile."alacritty/alacritty.toml" = lib.mkIf config.programs.alacritty.enable {
      force = true;
    };

    home.global-persistence.directories = [
      ".config/noctalia"
    ];
  };
}
