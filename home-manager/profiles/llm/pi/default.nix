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
      tokenSpeed.display = "ttft";
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

  home.file.".config/rpiv-ask-user-question/config.json".text = builtins.toJSON {
    guidance.promptGuidelines = [
      ''
        Keep each question to a single sentence stating the core decision;
        move all context and trade-offs into option descriptions — never dump
        long prose into the question field (it wraps badly).
      ''
      ''
        Keep labels to 1-5 words and descriptions to one line; multi-line
        content (commit message, diff, code, config, mockup) goes into the
        option's markdown preview — put it in a fenced code block, keep it
        brief.
      ''
      ''
        Put your recommended option first and append (Recommended) to its
        label; set multiSelect: true only when multiple answers are valid.
      ''
      ''
        Group every clarifying question into one ask_user_question call —
        never stack multiple calls back-to-back.
      ''
      ''
        Each question MUST have 2-4 options, each with a concise label and
        description; never author Other or Type something. labels yourself —
        they are reserved and rejected at runtime.
      ''
    ];
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
