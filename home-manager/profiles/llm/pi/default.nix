{ pkgs, lib, ... }:
let
  context = builtins.concatStringsSep "\n" (
    lib.map (name: lib.readFile ../rules/${name}) (lib.attrNames (lib.readDir ../rules))
  );
in
{
  programs.pi-coding-agent = {
    enable = true;
    package = pkgs.llm-agents.pi;
    inherit context;

    extraPackages = with pkgs; [
      nodejs
      bun
      rtk
    ];

    settings = {
      theme = "light/dark";
      collapseChangelog = true;
      enableInstallTelemetry = false;
      enableAnalytics = false;
      outputPad = 0;
      editorPaddingX = 0;
      hideThinkingBlock = true;
      terminal.showTerminalProgress = true;
      defaultProvider = "opencode-go";
      defaultModel = "deepseek-v4-flash";
      enabledModels = [
        "opencode-go/deepseek-v4-flash"
        "deepseek/deepseek-v4-flash"
      ];
      defaultThinkingLevel = "high";
      steeringMode = "all";
      packages = [
        # keep-sorted start
        "git:github.com/DietrichGebert/ponytail"
        "npm:pi-acp"
        "npm:pi-btw"
        "npm:pi-codex-goal"
        "npm:pi-interview"
        "npm:pi-mcp-adapter"
        "npm:pi-rtk-optimizer"
        "npm:pi-simplify"
        "npm:pi-subagents"
        "npm:pi-tian-usage"
        "npm:pi-tps"
        # keep-sorted end
      ];
    };
  };

  home.file.".pi/agent/pi-tps.json".text = builtins.toJSON {
    showTraces = true;
    showStats = true;
    showTtft = true;
    colorPreset = "theme";
    maxTraces = 100;
    maxDetailed = 1;
  };

  home.global-persistence.directories = [
    ".pi"
  ];

  programs.git.ignores = [
    "/.pi"
  ];
}
