{
  config,
  pkgs,
  lib,
  ...
}: let
  minioPort = config.ports.minio;
  minioConsolePort = config.ports.minio-console;
  minioAddress = "http://localhost:${toString minioPort}";
  minioRequiredProxyHeaders = pkgs.writeText "minio-required-proxy-headers.conf" ''
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Host $host;
  '';
  proxyPassToMinio = ''
    include ${minioRequiredProxyHeaders};
    proxy_pass ${minioAddress};
  '';
in {
  services.minio = {
    enable = true;
    # TODO wait for https://github.com/NixOS/nixpkgs/issues/199318
    package = pkgs.nur.repos.linyinfeng.minio-latest;
    listenAddress = "127.0.0.1:${toString minioPort}";
    consoleAddress = "127.0.0.1:${toString minioConsolePort}";
    rootCredentialsFile = config.sops.templates."minio-root-credentials".path;
  };
  systemd.services.minio.serviceConfig.ExecStart =
    # TODO wait for https://github.com/NixOS/nixpkgs/issues/199318
    let
      cfg = config.services.minio;
    in
      lib.mkForce "${cfg.package}/bin/minio server --address ${cfg.listenAddress} --console-address ${cfg.consoleAddress} --certs-dir /var/lib/minio/certs ${toString cfg.dataDir}";
  sops.secrets."minio/root/user" = {
    sopsFile = config.sops-file.get "hosts/rica-terraform.yaml";
    restartUnits = ["minio.service"];
  };
  sops.secrets."minio/root/password" = {
    sopsFile = config.sops-file.get "hosts/rica-terraform.yaml";
    restartUnits = ["minio.service"];
  };
  sops.templates."minio-root-credentials".content = ''
    MINIO_ROOT_USER=${config.sops.placeholder."minio/root/user"}
    MINIO_ROOT_PASSWORD=${config.sops.placeholder."minio/root/password"}
  '';
  services.nginx.virtualHosts."minio.*" = {
    forceSSL = true;
    useACMEHost = "main";
    locations."/".proxyPass = minioAddress;
    extraConfig = ''
      client_max_body_size 4G;
    '';
  };
  services.nginx.virtualHosts."cache.*" = {
    forceSSL = true;
    useACMEHost = "main";
    locations."/".extraConfig = ''
      rewrite /(.*) /cache/$1 break;
      ${proxyPassToMinio}
    '';
  };
  services.nginx.virtualHosts."minio-console.*" = {
    forceSSL = true;
    useACMEHost = "main";
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
  services.telegraf.extraConfig = {
    inputs.prometheus = [
      {
        urls = ["https://minio.li7g.com/minio/v2/metrics/cluster"];
        bearer_token = "$CREDENTIALS_DIRECTORY/minio_bearer_token";
        tags.output_bucket = "minio";
      }
    ];
  };
  systemd.services.telegraf.serviceConfig.LoadCredential = [
    "minio_bearer_token:${config.sops.secrets."minio_metrics_bearer_token".path}"
  ];
  sops.secrets."minio_metrics_bearer_token" = {
    sopsFile = config.sops-file.terraform;
    restartUnits = ["telegraf.service"];
  };
}