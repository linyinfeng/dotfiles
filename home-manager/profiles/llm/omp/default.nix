{ pkgs, lib, ... }:
with pkgs;
let
  agentsMd = pkgs.runCommand "omp-agents-md" { } ''
    cat ${../_context}/*.md > $out
  '';
in
{
  home.packages = [
    (writeShellApplication {
      name = "omp";
      runtimeInputs = [
        llm-agents.omp
        bun
      ];
      text = ''
        exec omp "$@"
      '';
    })
  ];

  home.file.".omp/agent/AGENTS.md" = {
    source = agentsMd;
  };

  home.merge.".omp/agent/config.yml".value = {
    # disable auto provider discovery
    disabledProviders = [
      "claude"
      "codex"
      "gemini"
      "opencode"
      "github"
      "cursor"
    ];
    # setupVersion is intentionally not declared: it is onboarding progress
    # (the wizard rewrites it when an upstream bump adds scenes) and the merge
    # keeps whatever omp wrote. Pinning it here would rewind it every switch and
    # re-run the wizard until the pin catches up with CURRENT_SETUP_VERSION.
    modelRoles.default = "commandcode/deepseek/deepseek-v4.1-flash:high";
    modelRoles.smol = "commandcode/deepseek/deepseek-v4.1-flash";
    modelRoles.slow = "xiaomi/mimo-v2.6-pro";
    modelRoles.vision = "opencode-go/mimo-v2.6-flash";
    modelRoles.web = "web/exa";
    # web role falls back down the search-provider list; google/ecosia/mojeek
    # are the providers the old providers.webSearchExclude dropped.
    retry.fallbackChains.web = [
      "web/parallel"
      "web/perplexity"
      "google-gemini-cli/gemini-2.5-flash"
      "google-antigravity/gemini-2.5-flash"
      "google/gemini-2.5-flash"
      "anthropic/claude-haiku-4-5"
      "openai-codex/gpt-5.6-luna"
      "openai-codex/gpt-5.6"
      "openai-codex/gpt-5.5"
      "xai/grok-4.5"
      "xai-oauth/grok-4.5"
      "web/zai"
      "web/tinyfish"
      "web/jina"
      "web/kagi"
      "web/tavily"
      "web/firecrawl"
      "web/brave"
      "web/kimi"
      "web/synthetic"
      "web/ollama"
      "web/searxng"
      "web/startpage"
      "web/duckduckgo"
      "web/public"
    ];
    hideThinkingBlock = true;
    statusLine.transparent = true;
    statusLine.preset = "custom";
    statusLine.separator = "powerline";
    statusLine.leftSegments = [
      "mode"
      "model"
      "collab"
      "subagents"
      "path"
      "git"
      "pr"
    ];
    statusLine.rightSegments = [
      "session_name"
      "context_pct"
      "cache_hit"
      "token_rate"
      "time_spent"
    ];
    terminal.showProgress = true;
    tui.tight = true;
    display.shimmer = "kitt";
    display.cacheMissMarker = true;
    steeringMode = "all";
    followUpMode = "all";
    bash.autoBackground.enabled = true;
    bashInterceptor.enabled = true;
    github.enabled = true;
    astGrep.enabled = true;
    autolearn.enabled = true;
    autolearn.autoContinue = true;
    checkpoint.enabled = true;
    compaction.idleEnabled = true;
    computer.enabled = true;
    composer.tokenRate = true;
    edit.enforceSeenLines = true;
    lsp.diagnosticsOnEdit = true;
    lsp.formatOnWrite = true;
    memory.backend = "sharpshooter";
    plan.enabled = false;
    power.sleepPrevention = "off";
    read.renderMarkdown = true;
    secrets.enabled = true;
  };

  home.merge.".omp/agent/mcp.json".value = {
    "$schema" =
      "https://raw.githubusercontent.com/can1357/oh-my-pi/main/packages/coding-agent/src/config/mcp-schema.json";
    mcpServers = {
      mcp-nixos = {
        type = "stdio";
        command = lib.getExe pkgs.mcp-nixos;
      };
      context7-mcp = {
        type = "stdio";
        command = lib.getExe pkgs.context7-mcp;
      };
    };
  };

  home.global-persistence.directories = [
    ".omp"
  ];

  programs.git.ignores = [
    "/.omp"
  ];
}
