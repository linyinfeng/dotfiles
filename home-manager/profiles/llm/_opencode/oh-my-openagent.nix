{ pkgs, ... }:
let
  jsonFormat = pkgs.formats.json { };

  orchestratorModels = [
    "opencode-go/kimi-k2.6"
    "opencode-go/glm-5.2"
    "opencode-go/deepseek-v4-pro"
    "xiaomi-token-plan-cn/mimo-v2.5-pro"
  ]
  ++ normalTaskModels;

  hardTaskModels = [
    "opencode-go/glm-5.2"
    "opencode-go/kimi-k2.6"
    "opencode-go/deepseek-v4-pro"
    "xiaomi-token-plan-cn/mimo-v2.5-pro"
  ]
  ++ normalTaskModels;

  normalTaskModels = [
    "opencode-go/deepseek-v4-flash"
    "opencode/deepseek-v4-flash-free"
    "xiaomi-token-plan-cn/mimo-v2.5"
  ];

  visionModels = [
    "opencode-go/mimo-v2.5"
    "opencode/mimo-v2.5-free"
    "xiaomi-token-plan-cn/mimo-v2.5"
  ];

  mkAgent = models: {
    model = builtins.head models;
    fallback_models = map (m: { model = m; }) (builtins.tail models);
  };

  orchestrator = mkAgent orchestratorModels;
  hardTask = mkAgent hardTaskModels;
  normalTask = mkAgent normalTaskModels;
  vision = mkAgent visionModels;
in
{
  xdg.configFile."opencode/oh-my-openagent.json" = {
    source = jsonFormat.generate "oh-my-openagent.json" {
      "$schema" =
        "https://github.com/code-yeongyu/oh-my-openagent/raw/refs/heads/dev/assets/oh-my-opencode.schema.json";
      model_fallback = true;
      runtime_fallback = {
        enabled = true;
        retry_on_errors = [
          429
          500
          502
          503
          504
        ];
        max_fallback_attempts = 5;
        cooldown_seconds = 60;
        notify_on_fallback = true;
      };
      agents = {
        sisyphus = orchestrator;
        oracle = hardTask;
        librarian = normalTask;
        explore = normalTask;
        multimodal-looker = vision;
        prometheus = orchestrator;
        metis = orchestrator;
        momus = hardTask;
        atlas = orchestrator;
        sisyphus-junior = orchestrator;
      };
      categories = {
        visual-engineering = orchestrator;
        ultrabrain = hardTask;
        deep = orchestrator;
        artistry = orchestrator;
        quick = normalTask;
        unspecified-low = normalTask;
        unspecified-high = hardTask;
        writing = orchestrator;
      };
    };
  };
  programs.git.ignores = [
    "/.codegraph"
    "/.omo"
  ];
}
