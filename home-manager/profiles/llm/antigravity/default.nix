{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.antigravity-cli;
  installDir = ".local/share/antigravity-cli/bin";

  appStoragePath =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/Antigravity/app_storage.json"
    else
      ".config/Antigravity/app_storage.json";

  manageHubStorage =
    pkgs.stdenv.hostPlatform.isDarwin || config.world.profiles.desktop-applications.enable;

  agy = pkgs.writeShellApplication {
    name = "agy";
    text = ''
      binary="$HOME/${installDir}/agy"
      if [ ! -x "$binary" ]; then
        printf 'agy is not installed; run agy-install\n' >&2
        exit 127
      fi
      exec "$binary" "$@"
    '';
  };

  agy-install = pkgs.writeShellApplication {
    name = "agy-install";
    runtimeInputs = with pkgs; [
      bash
      coreutils
      curl
      gnugrep
      gnused
      gnutar
      gzip
    ];
    text = ''
      # The installer skips shell PATH setup when the target is already on PATH.
      target="$HOME/${installDir}"
      export PATH="$target:$PATH"

      installer=$(mktemp)
      trap 'rm -f "$installer"' EXIT
      curl -fsSL https://antigravity.google/cli/install.sh -o "$installer"
      bash "$installer" --dir "$target"
      if [ ! -x "$target/agy" ]; then
        printf 'agy is missing or not executable at %s\n' "$target/agy" >&2
        exit 1
      fi
      printf 'agy binary: %s\n' "$target/agy"
    '';
  };
in
{
  options.programs.antigravity-cli = {
    daemon.enable = lib.mkEnableOption "the Antigravity CLI remote-control daemon";
  };

  config = lib.mkIf (lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.llm-agents.antigravity-cli) {
    # Keep the executable user-writable for Antigravity's built-in updater.
    home.packages = [
      agy
      agy-install
    ];

    home.file.".gemini/GEMINI.md".source = ../_context.md;

    # Both agy and Antigravity Hub rewrite their JSON configs at runtime, so
    # merge declared preferences instead of linking read-only store files.
    home.merge = {
      ".gemini/antigravity-cli/settings.json".value = {
        colorScheme = "terminal";
        altScreenMode = "default";
        agentMode = "accept-edits";
        toolPermission = "always-proceed";
        allowNonWorkspaceAccess = true;
        enableTerminalSandbox = true;
        queuedMessages = "send-immediately";
      };

      ".gemini/antigravity-cli/keybindings.json".value = {
        "prompt.submit_alternate" = [ "alt+enter" ];
        "prompt.insert_newline" = [
          "shift+enter"
          "ctrl+j"
        ];
      };

      ".gemini/config/config.json".value = {
        userSettings = {
          themeMode = "THEME_MODE_INHERIT";
          permissionPreset = "AGENT_PERMISSION_PRESET_TURBO";
          enableTerminalSandbox = true;
          autoExecutionPolicy = "CASCADE_COMMANDS_AUTO_EXECUTION_EAGER";
          nonWorkspaceFileAccessPolicy = "AGENT_SETTING_POLICY_ALLOW";
          queuedMessageDeliveryStrategy = "MESSAGE_DELIVERY_STRATEGY_NEXT_INVOCATION";
        };
      };
    }
    // lib.optionalAttrs manageHubStorage {
      # Hub's SettingsService compares boolean toggles strictly with `=== "true"`.
      ${appStoragePath}.value = {
        "jetski.typeface" = "system";
        keepComputerAwake = "true";
        runInBackground = "true";
      };
    };

    home.global-persistence.directories = [
      ".gemini"
      ".local/share/antigravity-cli"
    ];

    # Declare the unit here instead of using `agy remote-control start` so it
    # inherits the managed proxy environment and runs through the agy wrapper.
    systemd.user.services = lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && cfg.daemon.enable) {
      antigravity-cli-daemon = {
        Unit = {
          Description = "Antigravity CLI remote-control daemon";
          After = [ "network.target" ];
          ConditionFileIsExecutable = "${config.home.homeDirectory}/${installDir}/agy";
          StartLimitIntervalSec = 0;
        };
        Service = {
          Type = "simple";
          Environment = lib.mkIf config.home.env.proxy.enable config.home.env.proxy.stringEnvironment;
          ExecStart = "${agy}/bin/agy remote-control serve";
          Restart = "on-failure";
          RestartSec = "10s";
          RestartPreventExitStatus = 3;
          TimeoutStopSec = "30s";
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
  };
}
