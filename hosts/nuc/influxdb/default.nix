{ config, pkgs, ... }:

let
  cfg = config.hosts.nuc;
  setup = pkgs.substituteAll {
    src = ./setup.sh;
    isExecutable = true;
    inherit (pkgs.stdenvNoCC) shell;
    inherit (pkgs) influxdb2 curl;
    username = "yinfeng";
    org = "main-org";
    bucket = "main";
    retention = "14d";
  };
in
{
  services.influxdb2 = {
    enable = true;
    settings = {
      http-bind-address = ":${toString cfg.ports.influxdb}";
    };
  };
  systemd.services.influxdb2-setup = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${setup}";
      DynamicUser = true;
      LoadCredential = [
        "password:${config.sops.secrets."influxdb/password".path}"
        "token:${config.sops.secrets."influxdb/token".path}"
      ];
      StateDirectory = "influxdb2-setup";
    };
    environment = {
      INFLUX_HOST = "http://localhost:${toString cfg.ports.influxdb}";
      INFLUX_CONFIGS_PATH = "/var/lib/influxdb2-setup/configs";
    };
    after = [ "influxdb2.service" ];
    wantedBy = [ "multi-user.target" ];
  };
  sops.secrets."influxdb/password" = { };
  sops.secrets."influxdb/token" = { };
  environment.systemPackages = with pkgs; [
    influxdb2
  ];
  environment.global-persistence.directories = [
    "/var/lib/private/influxdb2"
    "/var/lib/private/influxdb2-setup"
  ];
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    cfg.ports.influxdb
  ];
}
