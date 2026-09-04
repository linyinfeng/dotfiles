{
  pkgs,
  config,
  osConfig,
  ...
}:
let
  context = pkgs.runCommand "pi-agents-md" { } ''
    cat ${../_context}/*.md > $out
  '';

  inherit (config.lib.file) mkOutOfStoreSymlink;

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
      agent-browser
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
        # keep-sorted start
        "cc-switch/gpt-5.6-sol"
        "deepseek/deepseek-v4-flash-vision-exp"
        "opencode-go/deepseek-v4-flash"
        "opencode-go/glm-5.3-flash"
        "opencode-go/hy4-preview"
        "opencode-go/omen-alpha"
        "openrouter/google/gemini-3.8-flash"
        "zai-coding-cn/glm-5.3-flash"
        # keep-sorted end
      ];
      defaultThinkingLevel = "high";
      steeringMode = "all";
      tokenSpeed.display = "ttft";
      packages = [
        # keep-sorted start
        "npm:@ff-labs/pi-fff"
        "npm:@juicesharp/rpiv-todo"
        "npm:@mrclrchtr/supi-context"
        "npm:@narumitw/pi-usage"
        "npm:pi-acp"
        "npm:pi-agent-browser-native"
        "npm:pi-background-tasks"
        "npm:pi-btw"
        "npm:pi-fabric"
        "npm:pi-lens"
        "npm:pi-mcp-adapter"
        # "npm:pi-hashline-edit-pro"
        "npm:pi-readseek"
        "npm:pi-rtk-optimizer"
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
  };

  home.file.".config/pi/web-search.json".source =
    mkOutOfStoreSymlink
      osConfig.sops.templates."pi-web-search-config".path;

  home.file.".config/nono/profiles/pi.json".source = ./nono-pi-profile.json;

  home.file.".pi/agent/auth.json".source = mkOutOfStoreSymlink osConfig.sops.templates."pi-auth".path;

  home.file.".pi/agent/models.json".text = builtins.toJSON {
    providers = {
      "cc-switch" = {
        name = "cc-switch";
        baseUrl = "http://127.0.0.1:15721/v1";
        apiKey = "sk-local";
        api = "openai-completions";
        models = [
          {
            id = "gpt-5.6-sol";
            name = "GPT-5.6 Sol";
            api = "openai-responses";
            reasoning = true;
            thinkingLevelMap = {
              off = "none";
              minimal = null;
              xhigh = "xhigh";
            };
            input = [
              "text"
              "image"
            ];
            contextWindow = 353000;
            maxTokens = 128000;
            cost = {
              input = 0;
              output = 0;
              cacheRead = 0;
              cacheWrite = 0;
            };
          }
        ];
      };
      opencode-go = {
        models = [
          {
            id = "omen-alpha";
            name = "Omen Alpha";
            api = "openai-completions";
            baseUrl = "https://opencode.ai/zen/go/v1";
            reasoning = true;
            compat = {
              supportsStore = false;
              supportsDeveloperRole = false;
              maxTokensField = "max_tokens";
            };
            thinkingLevelMap = {
              off = "none";
              minimal = null;
              low = "low";
              medium = null;
              high = "high";
              xhigh = null;
              max = null;
            };
            input = [
              "text"
              "image"
            ];
            contextWindow = 500000;
            maxTokens = 128000;
            cost = {
              input = 0.2;
              output = 0.66;
              cacheRead = 0.04;
              cacheWrite = 0;
            };
          }
        ];
      };
      openrouter = {
        modelOverrides = {
          "google/gemini-3.8-flash" = {
            compat = {
              openRouterRouting = {
                order = [ "google-vertex/global" ];
                allow_fallbacks = false;
              };
            };
          };
        };
      };
    };
  };

  home.packages = [ pi-sandbox ];

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
