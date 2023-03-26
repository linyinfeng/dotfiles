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
      CPUWeight = "idle";
      CPUQuota = "50%";
      MemoryMax = "128M";
      MemorySwapMax = "512M";
      LimitNPROC = "100";
    };
    path = with pkgs; [
      nixVersions.selected
      "/var/lib/ace-bot/.nix-profile"
    ];
  };
  users.groups.ace-bot-nix = {};
  nix.settings.allowed-users = ["ace-bot"];
  sops.secrets."telegram-bot/ace-bot/token" = {
    sopsFile = config.sops-file.host;
  };
}
