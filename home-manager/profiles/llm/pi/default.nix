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

  # git has no config that adds a trailer, but it reads any config from the
  # environment, so a prepare-commit-msg hook does it without a `git` shim.
  agent-hooks = pkgs.runCommand "pi-agent-git-hooks" { } ''
    mkdir -p $out
    cat > $out/chain <<'EOF'
    #!/bin/sh
    name=$(basename "$0")
    hooks=$(git config --local --get core.hooksPath)
    [ -n "$hooks" ] || hooks="$(git rev-parse --git-common-dir)/hooks"
    if [ -x "$hooks/$name" ]; then
      exec "$hooks/$name" "$@"
    fi
    exit 0
    EOF
    cat > $out/prepare-commit-msg <<'EOF'
    #!/bin/sh
    hooks=$(git config --local --get core.hooksPath)
    [ -n "$hooks" ] || hooks="$(git rev-parse --git-common-dir)/hooks"
    [ -x "$hooks/prepare-commit-msg" ] && "$hooks/prepare-commit-msg" "$@"
    git interpret-trailers --in-place --if-exists doNothing \
      --trailer 'Co-authored-by: Lin Yinfeng <lin.yinfeng@outlook.com>' "$1"
    EOF
    chmod +x $out/chain $out/prepare-commit-msg
    for name in applypatch-msg pre-applypatch post-applypatch pre-commit pre-merge-commit commit-msg post-commit pre-rebase post-checkout post-merge pre-push pre-auto-gc post-rewrite post-index-change sendemail-validate fsmonitor-watchman reference-transaction post-update; do
      cp $out/chain $out/$name
    done
    rm $out/chain
  '';

  # pi installs and updates itself into ~/.pi/agent/install through the
  # upstream managed installer, so nix only owns the entry point. The launcher
  # is reached indirectly: pi prepends ~/.pi/agent/bin to its children's PATH,
  # and by then the identity below is already in the environment.
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

      # The agent's commits are automation's, not the human's; the human keeps
      # the identity from the git profile.
      export GIT_AUTHOR_NAME=Nano
      export GIT_AUTHOR_EMAIL=nano@linyinfeng.com
      export GIT_COMMITTER_NAME=Nano
      export GIT_COMMITTER_EMAIL=nano@linyinfeng.com
      export GIT_CONFIG_COUNT=1
      export GIT_CONFIG_KEY_0=core.hooksPath
      export GIT_CONFIG_VALUE_0=${agent-hooks}

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
  imports = [
    ./_pi-cnf-adapter.nix
  ];

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
    defaultModel = "commandcode/deepseek/deepseek-v4.1-flash";
    enabledModels = [
      "litellm/deepseek/deepseek-flash"
      "litellm/commandcode/deepseek/deepseek-v4.1-flash"
      "litellm/xiaomi-coding-plan-cn/mimo-v2.6-flash"
      "litellm/xiaomi-coding-plan-cn/mimo-v2.6-pro"
    ];
    defaultThinkingLevel = "high";
    litellm.providers.litellm = {
      baseUrl = "https://llm.li7g.com";
      displayName = "Gateway";
    };
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

  home.file.".config/pi/web-search.json" = lib.mkIf (config.home.env.secretPaths ? piWebSearch) {
    source = mkOutOfStoreSymlink config.home.env.secretPaths.piWebSearch;
  };

  home.file.".pi/agent/auth.json" = lib.mkIf (config.home.env.secretPaths ? piAuth) {
    source = mkOutOfStoreSymlink config.home.env.secretPaths.piAuth;
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
