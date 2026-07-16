{ osConfig, ... }:
{
  programs.opencode.settings.provider = {
    relay-cun-ai = {
      name = "CUN.AI";
      npm = "@ai-sdk/openai-compatible";
      options = {
        baseURL = "https://www.cun.ai/v1";
        apiKey = "{file:${osConfig.sops.secrets."cun_ai_api_key".path}}";
      };
      models = {
        "gpt-5.6-luna" = {
          name = "GPT-5.6-Luna";
        };
        "gpt-5.6-terra" = {
          name = "GPT-5.6-terra";
        };
        "gpt-5.6-sol" = {
          name = "GPT-5.6-sol";
        };
      };
    };
  };
}
