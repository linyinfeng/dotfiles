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

  # The agent's commits are automation's, not the human's; the human keeps the
  # identity from the git profile.
  pi-package = pkgs.symlinkJoin {
    name = "pi-agent-git-identity";
    paths = [ (pkgs.llm-agents.pi.override { useBun = false; }) ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/pi \
        --set GIT_AUTHOR_NAME Nano \
        --set GIT_AUTHOR_EMAIL nano@linyinfeng.com \
        --set GIT_COMMITTER_NAME Nano \
        --set GIT_COMMITTER_EMAIL nano@linyinfeng.com \
        --set GIT_CONFIG_COUNT 1 \
        --set GIT_CONFIG_KEY_0 core.hooksPath \
        --set GIT_CONFIG_VALUE_0 ${agent-hooks}
    '';
  };

  pi-sandbox = pkgs.writeShellApplication {
    name = "pi-sandbox";
    runtimeInputs = [ pkgs.llm-agents.nono ];
    text = ''
      nono pull nolabs-ai/pi
      nono update
      exec nono run --profile pi --allow-cwd -- pi "$@"
    '';
  };

in
{
  imports = [
    ./_pi-cnf-adapter.nix
  ];

  programs.pi-coding-agent = {
    enable = true;
    package = pi-package;
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
      {
        source = "${config.xdg.configHome}/nono/packages/nolabs-ai/pi";
      }
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

  home.file.".config/nono/profiles/pi.json".source = ./nono-pi-profile.json;

  home.file.".pi/agent/auth.json" = lib.mkIf (config.home.env.secretPaths ? piAuth) {
    source = mkOutOfStoreSymlink config.home.env.secretPaths.piAuth;
  };

  home.packages = [
    pi-sandbox
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
