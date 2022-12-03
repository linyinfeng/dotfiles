{ config, pkgs, ... }:

let
  cfg = config.hosts.rica;
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
      http-bind-address = ":${toString config.ports.influxdb}";
    };
  };
  systemd.services.influxdb2-setup = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${setup}";
      DynamicUser = true;
      LoadCredential = [
        "password:${config.sops.secrets."influxdb_password".path}"
        "token:${config.sops.secrets."influxdb_token".path}"
      ];
      StateDirectory = "influxdb2-setup";
    };
    environment = {
      INFLUX_HOST = "http://localhost:${toString config.ports.influxdb}";
      INFLUX_CONFIGS_PATH = "/var/lib/influxdb2-setup/configs";
    };
    after = [ "influxdb2.service" ];
    wantedBy = [ "multi-user.target" ];
  };
  # TODO restartUnits: can't change password and token currently
  sops.secrets."influxdb_password" = {
    sopsFile = config.sops.secretsDir + /terraform/hosts/rica.yaml;
    restartUnits = [ "influxdb2-setup.service" ];
  };
  sops.secrets."influxdb_token" = {
    sopsFile = config.sops.secretsDir + /terraform/infrastructure.yaml;
    restartUnits = [ "influxdb2-setup.service" ];
  };
  environment.systemPackages = with pkgs; [
    influxdb2
  ];
  services.nginx.virtualHosts."influxdb.*" = {
    forceSSL = true;
    useACMEHost = "main";
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.ports.influxdb}/";
    };
  };
}
