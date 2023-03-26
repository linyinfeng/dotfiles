{
  config,
  inputs,
  pkgs,
  ...
}: {
  services.ace-bot = {
    enable = true;
    managerChatId = "148111617";
    tokenFile = config.sops.secrets."telegram-bot/ace-bot/token".path;
  };
  systemd.services.ace-bot = {
    serviceConfig = {
      CPUQuota = "20%";
      LimitNPROC = "100";
      ReadWritePaths = [
        "/nix/var/nix/profiles/per-user/ace-bot"
      ];
    };
    path = with pkgs; [
      nixVersions.selected
    ];
  };
  users.groups.ace-bot-nix = {};
  nix.settings.allowed-users = ["ace-bot"];
  sops.secrets."telegram-bot/ace-bot/token" = {
    sopsFile = config.sops-file.host;
  };
}
