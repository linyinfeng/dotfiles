{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.antigravity-cli;
  installDir = ".local/share/antigravity-cli/bin";

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
