{
  config,
  lib,
  ...
}: let
  port = config.ports.ssh-honeypot;
in {
  virtualisation.oci-containers.containers."ssh-honeypot" = {
    image = "docker.io/cowrie/cowrie:latest";
    extraOptions = ["--label" "io.containers.autoupdate=registry"];
    ports = ["${toString port}:2222/tcp"];
    environment =
      {
        COWRIE_HONEYPOT_HOSTNAME = config.networking.hostName;
        COWRIE_HONEYPOT_TIMEZONE = config.time.timeZone;
        COWRIE_HONEYPOT_AUTH_CLASS = "AuthRandom";
        COWRIE_SHELL_KERNEL_VERSION = "5.10.0-20-amd64";
        COWRIE_SHELL_KERNEL_BUILD_STRING = "#1 SMP Debian 5.10.158-2 (2022-12-13)";
      };
    environmentFiles = [
      config.sops.templates."cowrie-extra-env".path
    ];
    volumes = [
      "/var/lib/cowrie:/cowrie/var/lib/cowrie"
      "/var/log/cowrie:/cowrie/var/log/cowrie"
    ];
  };
  systemd.tmpfiles.rules = [
    "d /var/lib/cowrie 700 root root - -"
    "d /var/log/cowrie 700 root root - -"
  ];
  sops.templates."cowrie-extra-env".content = ''
    COWRIE_OUTPUT_TELEGRAM_ENABLED=true
    COWRIE_OUTPUT_TELEGRAM_BOT_TOKEN=${config.sops.placeholder."telegram-bot/push"}
    COWRIE_OUTPUT_TELEGRAM_CHAT_ID=148111617
  '';
  networking.firewall.allowedTCPPorts = [port];
}
