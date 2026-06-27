{ config, ... }:
{
  users.groups.llm = { };
  sops.secrets."deepseek_api_key" = {
    predefined.enable = true;
    restartUnits = [ ];
    group = "llm";
    mode = "440";
  };
  sops.secrets."mimo_api_key" = {
    predefined.enable = true;
    restartUnits = [ ];
    group = "llm";
    mode = "440";
  };
  sops.secrets."mimo_token_plan_api_key" = {
    predefined.enable = true;
    restartUnits = [ ];
    group = "llm";
    mode = "440";
  };
  sops.secrets."opencode_api_key" = {
    predefined.enable = true;
    restartUnits = [ ];
    group = "llm";
    mode = "440";
  };
  sops.secrets."openrouter_api_key" = {
    predefined.enable = true;
    restartUnits = [ ];
    group = "llm";
    mode = "440";
  };
  sops.secrets."mineru_api_key" = {
    predefined.enable = true;
    restartUnits = [ ];
    group = "llm";
    mode = "440";
  };
  sops.templates."opencode-auth" = {
    content = builtins.toJSON {
      deepseek = {
        key = config.sops.placeholder."deepseek_api_key";
        type = "api";
      };
      opencode = {
        key = config.sops.placeholder."opencode_api_key";
        type = "api";
      };
      opencode-go = {
        key = config.sops.placeholder."opencode_api_key";
        type = "api";
      };
      openrouter = {
        key = config.sops.placeholder."openrouter_api_key";
        type = "api";
      };
      xiaomi = {
        key = config.sops.placeholder."mimo_api_key";
        type = "api";
      };
      xiaomi-token-plan-cn = {
        key = config.sops.placeholder."mimo_token_plan_api_key";
        type = "api";
      };
    };
    group = "llm";
    mode = "440";
  };
}
