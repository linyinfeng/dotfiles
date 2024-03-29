{ config, pkgs, ... }:
let
  setup = pkgs.substituteAll {
    src = ./setup.sh;
    isExecutable = true;
    inherit (pkgs.stdenvNoCC) shell;
    inherit (pkgs) influxdb2 curl;
    username = "yinfeng";
    org = "main-org";
    bucket = "main";
    retention = "30d";
    ensureBuckets = [
      "system"
      "minio"
      "minecraft"
      "http"
    ];
  };
in
{
  services.influxdb2 = {
    enable = true;
    settings = {
      http-bind-address = ":${toString config.ports.influxdb}";
    };
  };
  system.build.influxdb2-setup-script = setup;
  systemd.services.influxdb2-setup = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.system.build.influxdb2-setup-script}";
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
    terraformOutput.enable = true;
    restartUnits = [ "influxdb2-setup.service" ];
  };
  sops.secrets."influxdb_token" = {
    terraformOutput.enable = true;
    restartUnits = [ "influxdb2-setup.service" ];
  };
  environment.systemPackages = with pkgs; [ influxdb2 ];
  services.nginx.virtualHosts."influxdb.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.ports.influxdb}/";
    };
  };

  services.notify-failure.services = [ "influxdb2" ];
}
