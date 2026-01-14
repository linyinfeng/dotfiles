{ config, ... }:
let
  minioPort = config.ports.minio;
  minioConsolePort = config.ports.minio-console;
  minioAddress = "http://localhost:${toString minioPort}";
in
{
  services.minio = {
    enable = true;
    # # use self-maintained minio
    # package = pkgs.linyinfeng.minio-latest;
    listenAddress = "127.0.0.1:${toString minioPort}";
    consoleAddress = "127.0.0.1:${toString minioConsolePort}";
    rootCredentialsFile = config.sops.templates."minio-root-credentials".path;
  };
  sops.secrets."minio_root_user" = {
    predefined.enable = true;
    restartUnits = [ "minio.service" ];
  };
  sops.secrets."minio_root_password" = {
    predefined.enable = true;
    restartUnits = [ "minio.service" ];
  };
  sops.templates."minio-root-credentials".content = ''
    MINIO_ROOT_USER=${config.sops.placeholder."minio_root_user"}
    MINIO_ROOT_PASSWORD=${config.sops.placeholder."minio_root_password"}
  '';
  services.nginx.virtualHosts."minio.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/".proxyPass = minioAddress;
    extraConfig = ''
      client_max_body_size 4G;
    '';
  };
  services.nginx.virtualHosts."minio-console.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/" = {
      proxyPass = "http://localhost:${toString minioConsolePort}";
      extraConfig = ''
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
      '';
    };
  };

  # metrics
  services.telegraf.extraConfig.outputs.influxdb_v2 = [
    (config.lib.telegraf.mkMainInfluxdbOutput "minio")
  ];
  services.telegraf.extraConfig = {
    inputs.prometheus = [
      {
        urls = [ "https://minio.li7g.com/minio/v2/metrics/cluster" ];
        bearer_token = "$CREDENTIALS_DIRECTORY/minio_bearer_token";
        tags.output_bucket = "minio";
      }
    ];
  };
  systemd.services.telegraf.serviceConfig.LoadCredential = [
    "minio_bearer_token:${config.sops.secrets."minio_metrics_bearer_token".path}"
  ];
  sops.secrets."minio_metrics_bearer_token" = {
    terraformOutput.enable = true;
    restartUnits = [ "telegraf.service" ];
  };
}
