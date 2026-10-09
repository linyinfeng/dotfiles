{ config, ... }:
{
  home-manager.sharedModules = [
    ({ lib, ... }: {
      home.env.secretPaths = {
        piWebSearch = lib.mkDefault config.sops.templates."pi-web-search-config".path;
        piAuth = lib.mkDefault config.sops.templates."pi-auth".path;
        mineruApiKey = lib.mkDefault config.sops.secrets."mineru_api_key".path;
      };
    })
  ];

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
  sops.secrets."command_code_api_key" = {
    predefined.enable = true;
    restartUnits = [ ];
    group = "llm";
    mode = "440";
  };
  sops.secrets."litellm_api_key" = {
    predefined.enable = true;
    restartUnits = [ ];
    group = "llm";
    mode = "440";
  };
  sops.templates."pi-web-search-config" = {
    content = builtins.toJSON {
      workflow = "auto-summary";
      perplexityApiKey = config.sops.placeholder."perplexity_api_key";
      fetch = {
        answerProvider = "litellm";
        answerModel = "deepseek/deepseek-flash";
      };
      # TUN fake-IP proxies resolve public names into the synthetic range
      ssrf.allowRanges = [ "198.18.0.0/15" ];
    };
    group = "llm";
    mode = "440";
  };
  sops.templates."pi-auth" = {
    content = builtins.toJSON {
      litellm = {
        key = config.sops.placeholder."litellm_api_key";
        type = "api_key";
      };
    };
    group = "llm";
    mode = "440";
  };
}
