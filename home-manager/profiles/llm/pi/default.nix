{
  pkgs,
  config,
  ...
}:
let
  context = pkgs.runCommand "pi-agents-md" { } ''
    cat ${../_context}/*.md > $out
  '';

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
  programs.pi-coding-agent = {
    enable = true;
    package = pkgs.llm-agents.pi.override {
      useBun = false;
    };
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
        "opencode-go/deepseek-v4-pro"
        "deepseek/deepseek-v4-pro"
      ];
      defaultThinkingLevel = "high";
      steeringMode = "all";
      packages = [
        # keep-sorted start
        "npm:@99percentpeople/pi-background-tasks"
        "npm:@dietrichgebert/ponytail"
        "npm:@ff-labs/pi-fff"
        "npm:@juicesharp/rpiv-ask-user-question"
        "npm:@juicesharp/rpiv-todo"
        "npm:@mrclrchtr/supi-context"
        "npm:pi-acp"
        "npm:pi-btw"
        "npm:pi-hashline-edit-pro"
        "npm:pi-lens"
        "npm:pi-mcp-adapter"
        "npm:pi-rtk-optimizer"
        "npm:pi-simplify"
        "npm:pi-subagents"
        "npm:pi-tian-usage"
        "npm:pi-token-speed"
        "npm:pi-web-access"
        {
          source = "${config.xdg.configHome}/nono/packages/nolabs-ai/pi";
        }
        # keep-sorted end
      ];
    };
  };

  home.file.".config/pi/web-search.json".text = builtins.toJSON {
    workflow = "auto-summary";
  };

  home.file.".config/nono/profiles/pi.json".source = ./nono-pi-profile.json;

  home.packages = [ pi-sandbox ];

  home.global-persistence.directories = [
    ".pi"
    ".pi-lens"
  ];

  programs.git.ignores = [
    "/.pi"
    "/.pi-subagents"
  ];
}
