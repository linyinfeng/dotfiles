{ pkgs, ... }:
with pkgs;
let
  yaml = pkgs.formats.yaml { };
  json = pkgs.formats.json { };

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

  home.file.".omp/agent/config.yml" = {
    source = yaml.generate "omp-agent-config" {
      providers.webSearchOrder = [
        "exa"
      ];
      providers.webSearchExclude = [
        "google"
        "ecosia"
        "mojeek"
      ];
      # disable auto provider discovery
      disabledProviders = [
        "claude"
        "codex"
        "gemini"
        "opencode"
        "github"
        "cursor"
      ];
      setupVersion = 1;
      modelRoles.default = "opencode-go/deepseek-v4-flash";
      modelRoles.vision = "opencode-go/mimo-v2.5";
      hideThinkingBlock = true;
      statusLine.transparent = true;
      statusLine.preset = "custom";
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
      tui.scrollbackRebuild = true;
      display.shimmer = "kitt";
      display.cacheMissMarker = true;
      steeringMode = "all";
      followUpMode = "all";
      bash.autoBackground.enabled = true;
      bashInterceptor.enabled = true;
      github.enabled = true;
      astGrep.enabled = true;
      checkpoint.enabled = true;
      compaction.idleEnabled = true;
      edit.enforceSeenLines = true;
      lsp.diagnosticsOnEdit = true;
      lsp.formatOnWrite = true;
      read.renderMarkdown = true;
      secrets.enabled = true;
    };
    force = true;
  };

  home.file.".omp/agent/mcp.json" = {
    source = json.generate "omp-mcp-config" {
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
    force = true;
  };

  home.global-persistence.directories = [
    ".omp"
  ];

  programs.git.ignores = [
    "/.omp"
  ];
}
