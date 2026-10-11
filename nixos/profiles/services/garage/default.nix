{
  config,
  pkgs,
  ...
}:
let
  inherit (config) ports;
  vhostTls = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
  };
in
{
  services.garage = {
    enable = true;
    package = pkgs.garage_2;
    environmentFile = config.sops.templates."garage-env".path;
    settings = {
      db_engine = "lmdb";
      metadata_auto_snapshot_interval = "6h";
      replication_factor = 3;

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
    restartUnits = [ "garage.service" ];
  };
  sops.secrets."garage_admin_token" = {
    terraformOutput.enable = true;
    restartUnits = [ "garage.service" ];
  };
  sops.secrets."garage_metrics_token" = {
    terraformOutput.enable = true;
    restartUnits = [ "garage.service" ];
  };
  systemd.services.garage.restartTriggers = [ config.sops.templates."garage-env".content ];

  # peers reach this node over tailscale, dn42 or the public internet; the RPC
  # secret authenticates them, so RPC is allowed on every transport
  networking.firewall.allowedTCPPorts = [ ports.garage-rpc ];

  services.nginx.virtualHosts = {
    "s3.*" = vhostTls // {
      serverAliases = [
        "*.s3.li7g.com"
        # regional entry points to the same cluster
        "s3-ca.li7g.com"
        "s3-hk.li7g.com"
        "s3-cn.li7g.com"
      ];
      locations."/".proxyPass = "http://[::1]:${toString ports.garage-s3}";
      extraConfig = ''
        client_max_body_size 4G;
      '';
    };
    "s3-web.*" = vhostTls // {
      serverAliases = [ "*.s3-web.li7g.com" ];
      locations."/".proxyPass = "http://[::1]:${toString ports.garage-web}";
    };
    "garage-admin.*" = vhostTls // {
      locations."/".proxyPass = "http://[::1]:${toString ports.garage-admin}";
    };
  };
}
