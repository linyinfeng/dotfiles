{ osConfig, ... }:
{
  programs.opencode.settings.provider = {
    arc-coding-plan = {
      name = "Volcano Engine (Coding Plan)";
      npm = "@ai-sdk/openai-compatible";
      options = {
        baseURL = "https://ark.cn-beijing.volces.com/api/coding/v3";
        apiKey = "{file:${osConfig.sops.secrets."ark_coding_plan_api_key".path}}";
      };
      models = {
        ark-code-latest = {
          name = "ark-code-latest";
        };
        deepseek-v4-flash = {
          limit = {
            context = 1048576;
            output = 4096;
          };
          modalities = {
            input = [ "text" ];
            output = [ "text" ];
          };
          name = "deepseek-v4-flash";
        };
        deepseek-v4-pro = {
          limit = {
            context = 1048576;
            output = 4096;
          };
          modalities = {
            input = [ "text" ];
            output = [ "text" ];
          };
          name = "deepseek-v4-pro";
        };
        "glm-5.2" = {
          limit = {
            context = 1048576;
            output = 4096;
          };
          modalities = {
            input = [ "text" ];
            output = [ "text" ];
          };
          name = "glm-5.2";
        };
        "kimi-k2.6" = {
          name = "kimi-k2.6";
        };
        "kimi-k2.7-code" = {
          name = "kimi-k2.7-code";
        };
        "minimax-m2.7" = {
          name = "minimax-m2.7";
        };
        minimax-m3 = {
          name = "minimax-m3";
        };
      };
    };
  };
}
