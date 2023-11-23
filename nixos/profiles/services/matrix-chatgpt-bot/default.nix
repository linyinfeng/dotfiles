{
  config,
  pkgs,
  lib,
  ...
}: {
  systemd.services."matrix-chatgpt-bot" = {
    script = ''
      ${pkgs.nur.repos.linyinfeng.matrix-chatgpt-bot}/bin/matrix-chatgpt-bot
    '';
    serviceConfig = {
      DynamicUser = true;
      Restart = "on-failure";
      StateDirectory = "matrix-chatgpt-bot";
      EnvironmentFile = [
        config.sops.templates."matrix-chatgpt-extra-env".path
      ];
    };
    environment = {
      DATA_PATH = "/var/lib/matrix-chatgpt-bot";

      CHATGPT_CONTEXT = "thread";
      # https://platform.openai.com/docs/models/gpt-4-and-gpt-4-turbo
      CHATGPT_API_MODEL = "gpt-4-1106-preview";
      CHATGPT_PROMPT_PREFIX = ''
        You are ChatGPT, a large language model trained by OpenAI. Answer as concisely as possible.
        Knowledge cutoff: 2023-04
      '';
      # https://github.com/matrixgpt/matrix-chatgpt-bot?tab=readme-ov-file#how-to-set-the-temperature
      CHATGPT_TEMPERATURE = "0.8";
      # save money, gpt-4-turble: $0.01 per 1k input tokens, $0.03 per 1k output tokens
      CHATGPT_MAX_CONTEXT_TOKENS = "4097";
      CHATGPT_MAX_PROMPT_TOKENS = "3097";

      KEYV_BACKEND = "file";
      KEYV_URL = "";
      KEYV_BOT_ENCRYPTION = "false";
      KEYV_BOT_STORAGE = "true";

      MATRIX_HOMESERVER_URL = "https://matrix.li7g.com";
      MATRIX_BOT_USERNAME = "@chatgptbot:li7g.com";

      MATRIX_DEFAULT_PREFIX = "!chatgpt";
      MATRIX_DEFAULT_PREFIX_REPLY = "false";

      # MATRIX_BLACKLIST = "";
      # MATRIX_WHITELIST = "@yinfeng:li7g.com";
      # MATRIX_ROOM_BLACKLIST = "";
      MATRIX_ROOM_WHITELIST = lib.concatStringsSep " " [
        "!clkyAURLHpXBYpcfSE:li7g.com" # public - #njulug:li7g.com
        "!zTlANVtTbdIAFwxyBS:li7g.com" # private - #chatgpt:li7g.com
        "!MPQSzGQmrbZGaDnPaL:li7g.com" # private - #apartment-five:li7g.com
        "!cacbMwUwsLZ6GKac:nichi.co" # public - #zh-cn:nixos.org
      ];

      MATRIX_AUTOJOIN = "true";
      MATRIX_ENCRYPTION = "true";
      MATRIX_THREADS = "true";
      MATRIX_PREFIX_DM = "false";
      MATRIX_RICH_TEXT = "true";
    };
    wantedBy = ["multi-user.target"];
  };
  sops.templates."matrix-chatgpt-extra-env".content = ''
    OPENAI_API_KEY=${config.sops.placeholder."chatgpt-bot/openai-api-key"}
    MATRIX_BOT_PASSWORD=${config.sops.placeholder."chatgpt-bot/matrix-password"}
    MATRIX_ACCESS_TOKEN=${config.sops.placeholder."chatgpt-bot/matrix-access-token"}
  '';
  sops.secrets."chatgpt-bot/openai-api-key" = {
    sopsFile = config.sops-file.host;
    restartUnits = ["matrix-chatgpt-bot.service"];
  };
  sops.secrets."chatgpt-bot/matrix-password" = {
    sopsFile = config.sops-file.host;
    restartUnits = ["matrix-chatgpt-bot.service"];
  };
  sops.secrets."chatgpt-bot/matrix-access-token" = {
    sopsFile = config.sops-file.host;
    restartUnits = ["matrix-chatgpt-bot.service"];
  };
}
