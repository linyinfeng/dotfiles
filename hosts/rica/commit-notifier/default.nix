{ config, ... }:

{
  services.commit-notifier = {
    enable = true;
    cron = "0 */5 * * * *";
    tokenFile = config.sops.secrets."telegram-bot/commit-notifier".path;
  };
  sops.secrets."telegram-bot/commit-notifier" = {
    sopsFile = config.sops.getSopsFile "hosts/rica.yaml";
    restartUnits = [ "commit-notifier.service" ];
  };

  services.notify-failure.services = [
    "commit-notifier"
  ];
}
