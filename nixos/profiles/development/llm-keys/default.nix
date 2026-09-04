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
  sops.secrets."nvidia_api_key" = {
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
  sops.secrets."voyage_ai_api_key" = {
    predefined.enable = true;
    restartUnits = [ ];
    group = "llm";
    mode = "440";
  };
  sops.secrets."ark_coding_plan_api_key" = {
    predefined.enable = true;
    restartUnits = [ ];
    group = "llm";
    mode = "440";
  };
  sops.secrets."gemini_api_key" = {
    predefined.enable = true;
    restartUnits = [ ];
    group = "llm";
    mode = "440";
  };
  sops.secrets."perplexity_api_key" = {
    predefined.enable = true;
    restartUnits = [ ];
    group = "llm";
    mode = "440";
  };
  sops.secrets."xai_api_key" = {
    predefined.enable = true;
    restartUnits = [ ];
    group = "llm";
    mode = "440";
  };
  sops.secrets."zhipu_api_key" = {
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
      nvidia = {
        key = config.sops.placeholder."nvidia_api_key";
        type = "api";
      };
    };
    group = "llm";
    mode = "440";
  };
  sops.templates."pi-web-search-config" = {
    content = builtins.toJSON {
      workflow = "auto-summary";
      perplexityApiKey = config.sops.placeholder."perplexity_api_key";
    };
    group = "llm";
    mode = "440";
  };
  sops.templates."pi-auth" = {
    content = builtins.toJSON {
      deepseek = {
        key = config.sops.placeholder."deepseek_api_key";
        type = "api_key";
      };
      opencode = {
        key = config.sops.placeholder."opencode_api_key";
        type = "api_key";
      };
      opencode-go = {
        key = config.sops.placeholder."opencode_api_key";
        type = "api_key";
      };
      openrouter = {
        key = config.sops.placeholder."openrouter_api_key";
        type = "api_key";
      };
      xai = {
        key = config.sops.placeholder."xai_api_key";
        type = "api_key";
      };
      "zai-coding-cn" = {
        key = config.sops.placeholder."zhipu_api_key";
        type = "api_key";
      };
    };
    group = "llm";
    mode = "440";
  };
}
