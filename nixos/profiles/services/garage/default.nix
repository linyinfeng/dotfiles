{ config, pkgs, ... }:
let
  inherit (config) ports;
in
{
  services.garage = {
    enable = true;
    package = pkgs.garage_2;
    environmentFile = config.sops.templates."garage-env".path;
    settings = {
      db_engine = "sqlite";
      replication_factor = 1;

      rpc_bind_addr = "[::]:${toString ports.garage-rpc}";
      rpc_public_addr = "${config.networking.hostName}.ts.li7g.com:${toString ports.garage-rpc}";

      s3_api = {
        s3_region = "garage";
        api_bind_addr = "[::1]:${toString ports.garage-s3}";
        root_domain = "s3.li7g.com";
      };
      s3_web = {
        bind_addr = "[::1]:${toString ports.garage-web}";
        root_domain = "s3-web.li7g.com";
      };
      admin = {
        api_bind_addr = "[::1]:${toString ports.garage-admin}";
      };
    };
  };
  sops.templates."garage-env".content = ''
    GARAGE_RPC_SECRET=${config.sops.placeholder."garage_rpc_secret"}
    GARAGE_ADMIN_TOKEN=${config.sops.placeholder."garage_admin_token"}
    GARAGE_METRICS_TOKEN=${config.sops.placeholder."garage_metrics_token"}
  '';
  sops.secrets."garage_rpc_secret" = {
    terraformOutput.enable = true;
    restartUnits = [ "garage.service" ]; # TODO
  };
  sops.secrets."garage_admin_token" = {
    terraformOutput.enable = true;
    restartUnits = [ "garage.service" ]; # TODO
  };
  sops.secrets."garage_metrics_token" = {
    terraformOutput.enable = true;
    restartUnits = [ "garage.service" ]; # TODO
  };
  # TODO
  systemd.services.garage.restartTriggers = [ config.sops.templates."garage-env".content ];

  services.nginx.virtualHosts."s3.*" = {
    serverAliases = [ "*.s3.li7g.com" ];
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/".proxyPass = "http://[::1]:${toString ports.garage-s3}";
    extraConfig = ''
      client_max_body_size 4G;
    '';
  };
  services.nginx.virtualHosts."s3-web.*" = {
    serverAliases = [ "*.s3-web.li7g.com" ];
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/".proxyPass = "http://[::1]:${toString ports.garage-web}";
  };
  services.nginx.virtualHosts."garage-admin.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/".proxyPass = "http://[::1]:${toString ports.garage-admin}";
  };

  # metrics
  services.telegraf.extraConfig.outputs.influxdb_v2 = [
    (config.lib.telegraf.mkMainInfluxdbOutput "garage")
  ];
  services.telegraf.extraConfig = {
    inputs.prometheus = [
      {
        urls = [ "https://garage-admin.li7g.com" ];
        bearer_token = "$CREDENTIALS_DIRECTORY/garage_bearer_token";
        tags.output_bucket = "garage";
      }
    ];
  };
  systemd.services.telegraf.serviceConfig.LoadCredential = [
    "garage_bearer_token:${config.sops.secrets."garage_metrics_token".path}"
  ];
}
