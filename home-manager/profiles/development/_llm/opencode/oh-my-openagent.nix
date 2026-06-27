{ pkgs, ... }:
let
  jsonFormat = pkgs.formats.json { };

  mkAgent = models: {
    model = builtins.head models;
    fallback_models = map (m: { model = m; }) (builtins.tail models);
  };

  orchestrator = mkAgent [
    "opencode-go/kimi-k2.6"
    "opencode-go/glm-5.2"
    "xiaomi-token-plan-cn/mimo-v2.5-pro"
    "opencode-go/deepseek-v4-pro"
    "opencode/deepseek-v4-pro"
  ];

  hardTask = mkAgent [
    "opencode-go/glm-5.2"
    "opencode-go/kimi-k2.6"
    "xiaomi-token-plan-cn/mimo-v2.5-pro"
    "opencode-go/deepseek-v4-pro"
    "opencode/deepseek-v4-pro"
  ];

  normalTask = mkAgent [
    "opencode-go/deepseek-v4-flash"
    "opencode/deepseek-v4-flash-free"
    "xiaomi-token-plan-cn/mimo-v2.5"
    "deepseek/deepseek-v4-flash"
  ];

  vision = mkAgent [
    "opencode-go/mimo-v2.5"
    "opencode/mimo-v2.5-free"
    "xiaomi-token-plan-cn/mimo-v2.5"
  ];
in
{
  xdg.configFile."opencode/oh-my-openagent.json" = {
    source = jsonFormat.generate "oh-my-openagent.json" {
      "$schema" =
        "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-openencode.schema.json";
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
}
