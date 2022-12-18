{ config, ... }:

{
  services.loki = {
    enable = true;
    extraFlags = [ "-config.expand-env=true" ];
    configuration = {
      auth_enabled = false;
      server.http_listen_port = config.ports.loki;
      common = {
        path_prefix = config.services.loki.dataDir;
        ring.kvstore.store = "inmemory";
      };
      ingester = {
        lifecycler = {
          ring.replication_factor = 1;
          final_sleep = "0s";
        };
        chunk_idle_period = "5m";
        chunk_retain_period = "30s";
      };
      schema_config.configs = [
        {
          from = "2020-10-24";
          store = "boltdb-shipper";
          object_store = "s3";
          schema = "v11";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];
      ruler = {
        storage = {
          type = "s3";
          s3 = {
            bucketnames = "loki-ruler";
            endpoint = "minio.li7g.com";
            region = "us-east-1";
            access_key_id = "\${MINIO_LOKI_KEY_ID}";
            secret_access_key = "\${MINIO_LOKI_ACCESS_KEY}";
            s3forcepathstyle = true;
          };
        };
        rule_path = "rules";
        enable_api = true;
        enable_alertmanager_v2 = true;
        alertmanager_url = "https://alertmanager.li7g.com";
        alertmanager_client = {
          basic_auth_username = "alertmanager";
          basic_auth_password = "\${ALERTMANAGER_PASSWORD}";
        };
      };
      storage_config = {
        boltdb_shipper = {
          active_index_directory = "loki/index";
          cache_location = "loki/index_cache";
          shared_store = "s3";
        };
        aws = {
          bucketnames = "loki";
          endpoint = "minio.li7g.com";
          region = "us-east-1";
          access_key_id = "\${MINIO_LOKI_KEY_ID}";
          secret_access_key = "\${MINIO_LOKI_ACCESS_KEY}";
          s3forcepathstyle = true;
        };
      };
      limits_config = {
        retention_period = "336h"; # 14 days
      };
      compactor = {
        working_directory = "data/compactor";
        shared_store = "s3";
        retention_enabled = true;
      };
    };
  };
  systemd.services.loki.serviceConfig.EnvironmentFile = [
    config.sops.templates."loki-env".path
  ];
  sops.templates."loki-env".content = ''
    ALERTMANAGER_PASSWORD=${config.sops.placeholder."alertmanager_password"}
    MINIO_LOKI_KEY_ID=${config.sops.placeholder."minio_loki_key_id"}
    MINIO_LOKI_ACCESS_KEY=${config.sops.placeholder."minio_loki_access_key"}
  '';

  services.nginx.virtualHosts."loki.*" = {
    forceSSL = true;
    useACMEHost = "main";
    locations."/" = {
      proxyPass = "http://localhost:${toString config.ports.loki}";
      extraConfig = ''
        auth_basic "loki";
        auth_basic_user_file ${config.sops.templates."loki-auth-file".path};
      '';
    };
  };
  sops.templates."loki-auth-file" = {
    content = ''
      loki:${config.sops.placeholder."loki_hashed_password"}
    '';
    owner = "nginx";
  };
  sops.secrets."loki_hashed_password" = {
    sopsFile = config.sops.getSopsFile "terraform/hosts/rica.yaml";
    restartUnits = [ "nginx.service" ];
  };
  sops.secrets."alertmanager_password" = {
    sopsFile = config.sops.getSopsFile "terraform/infrastructure.yaml";
    restartUnits = [ "loki.service" ];
  };
  sops.secrets."minio_loki_key_id" = {
    sopsFile = config.sops.getSopsFile "terraform/hosts/rica.yaml";
    restartUnits = [ "loki.service" ];
  };
  sops.secrets."minio_loki_access_key" = {
    sopsFile = config.sops.getSopsFile "terraform/hosts/rica.yaml";
    restartUnits = [ "loki.service" ];
  };
}
