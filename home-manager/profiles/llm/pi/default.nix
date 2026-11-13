{
  pkgs,
  config,
  lib,
  ...
}:
let
  context = pkgs.runCommand "pi-agents-md" { } ''
    cat ${../_context}/*.md ${./_context}/*.md > $out
  '';

  inherit (config.lib.file) mkOutOfStoreSymlink;

  secretPaths = config.home.env.secretPaths;

  # pi locks and rewrites auth.json, so it cannot live in the read-only secrets dir
  litellmApiKey = lib.optionalAttrs (secretPaths ? litellmApiKey) {
    apiKey = "!cat ${secretPaths.litellmApiKey}";
  };

  # pi installs and updates itself into ~/.pi/agent/install through the
  # upstream managed installer, so nix only owns the entry point.
  pi-wrapper = pkgs.writeShellApplication {
    name = "pi";
    runtimeInputs = with pkgs; [
      ast-grep
      bun
      nodejs
      rtk
    ];
    text = ''
      launcher="''${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/bin/pi"
      if [ ! -x "$launcher" ]; then
        printf 'pi is not installed; run pi-install\n' >&2
        exit 127
      fi

      exec "$launcher" "$@"
    '';
  };

  # Bootstrap or reinstall through the upstream installer. It refuses to replace
  # a pi that is not its own managed launcher, so hide every other pi and put
  # the managed bin dir first; the installer then finds the install on PATH and
  # leaves shell profiles alone. setsid drops the controlling terminal so the
  # installer takes its non-interactive path instead of showing the action menu.
  pi-install = pkgs.writeShellApplication {
    name = "pi-install";
    runtimeInputs = with pkgs; [
      bash
      coreutils
      curl
      nodejs
      util-linux
    ];
    text = ''
      agent_dir="''${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
      export PI_MANAGED_INSTALL_ROOT="$agent_dir/install"

      old_ifs=$IFS
      IFS=:
      new_path="$agent_dir/bin"
      for dir in $PATH; do
        [ -n "$dir" ] || continue
        if [ "$dir" = "$agent_dir/bin" ]; then
          continue
        fi
        if [ -x "$dir/pi" ]; then
          continue
        fi
        new_path="$new_path:$dir"
      done
      IFS=$old_ifs
      export PATH="$new_path"

      curl -fsSL https://pi.dev/install.sh | setsid --wait sh
    '';
  };

in
{
  programs.pi-coding-agent = {
    enable = true;
    package = null;
    inherit context;

    extraPackages = with pkgs; [
      ast-grep
      bun
      nodejs
      rtk
    ];
  };

  # pi, cc-switch and /model rewrite these at runtime, so the switch merges into
  # them instead of linking; a pick made in the TUI lasts until the next rebuild.
  home.merge.".pi/agent/settings.json".value = {
    theme = "light/dark";
    collapseChangelog = true;
    enableInstallTelemetry = false;
    outputPad = 0;
    hideThinkingBlock = true;
    terminal.showTerminalProgress = true;
    defaultProvider = "litellm";
    defaultModel = "default";
    defaultThinkingLevel = "high";
    enabledModels = [ "litellm/**" ];
    litellm.providers.litellm = {
      baseUrl = "https://llm.li7g.com";
      displayName = "Gateway";
    }
    // litellmApiKey;
    defaultTools = [
      "+codemode"
      "+find"
      "+grep"
      "+ls"
    ];
    steeringMode = "all";
    tokenSpeed = {
      display = "ttft";
      useProviderTokens = true;
      thresholds = {
        slow = 30;
        medium = 60;
        fast = 100;
        blazing = 200;
      };
    };
    packages = [
      # keep-sorted start
      "npm:@juicesharp/rpiv-todo"
      "npm:@narumitw/pi-usage"
      "npm:@xynogen/pix-sudo"
      "npm:pi-background-tasks"
      "npm:pi-browser-use"
      "npm:pi-btw"
      "npm:pi-goal-x"
      "npm:pi-interactive-shell"
      "npm:pi-lens"
      "npm:pi-provider-litellm"
      "npm:pi-simplify"
      "npm:pi-subagents"
      "npm:pi-token-speed"
      "npm:pi-web-access"
      # keep-sorted end
    ];
  };

  home.merge.".pi/agent/models.json".value = {
    # providers live in the file itself (cc-switch, /model, hand edits);
    # nothing is declared here, the switch only supplies an empty default.
    providers = { };
  };

  home.merge.".pi/agent/mcp.json".value = {
    mcpServers = lib.mapAttrs (
      _: server:
      lib.filterAttrs (_: value: value != null && value != [ ] && value != { }) server
      // {
        exposure = "deferred";
      }
    ) config.programs.mcp.servers;
  };

  home.file.".pi/agent/extensions/host-status.ts".source = ./_extensions/host-status.ts;

  home.file.".config/pi/web-search.json" = lib.mkIf (secretPaths ? piWebSearch) {
    source = mkOutOfStoreSymlink secretPaths.piWebSearch;
  };

  home.packages = [
    pi-wrapper
    pi-install
  ];

  # pi-lens: prefer PATH tools only, no self-install of npm binaries
  home.sessionVariables = {
    PI_LENS_DISABLE_TOOL_INSTALL = "1";
    PI_LENS_DISABLE_LSP_INSTALL = "1";
  };

  home.global-persistence.directories = [
    ".pi"
    ".pi-lens"
  ];

  programs.git.ignores = [
    "/.pi"
    "/.pi-glla"
    "/.pi-subagents"
  ];
}
