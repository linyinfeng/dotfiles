{
  config,
  ...
}:
{
  services.tsukkomi = {
    xiaomiMimoApiKeyFile = config.sops.secrets."tsukkomi_mimo_api_key".path;
    extraArgs = [ ];
    matrix = {
      enable = true;
      homeserver = "https://matrix.li7g.com";
      username = "@yuuko:li7g.com";
      passwordFile = config.sops.secrets."tsukkomi_matrix_password".path;
      recoveryKeyFile = config.sops.secrets."tsukkomi_matrix_recovery_key".path;
      rooms = [
        "!FBYsfMYohJUZBoybDG:li7g.com"
        "!clkyAURLHpXBYpcfSE:li7g.com"
      ];
      extraArgs = [ ];
    };
    telegram = {
      enable = true;
      tokenFile = config.sops.secrets."tsukkomi_telegram_token".path;
      chats = [
        "148111617"
        "-1001633375149"
      ];
      extraArgs = [ ];
    };
  };
  sops.secrets."tsukkomi_mimo_api_key" = {
    predefined.enable = true;
    restartUnits = [
      "tsukkomi-matrix.service"
      "tsukkomi-telegram.service"
    ];
  };
  sops.secrets."tsukkomi_matrix_password" = {
    predefined.enable = true;
    restartUnits = [ "tsukkomi-matrix.service" ];
  };
  sops.secrets."tsukkomi_matrix_recovery_key" = {
    predefined.enable = true;
    restartUnits = [ "tsukkomi-matrix.service" ];
  };
  sops.secrets."tsukkomi_telegram_token" = {
    predefined.enable = true;
    restartUnits = [ "tsukkomi-telegram.service" ];
  };
}
