{config, ...}: {
  services.loki = {
    enable = true;
    extraFlags = ["-config.expand-env=true"];
    configuration = {
      auth_enabled = false;
      server.http_listen_port = config.ports.loki;

      common = {
        path_prefix = config.services.loki.dataDir;
        replication_factor = 1;
        ring = {
          instance_addr = "127.0.0.1";
          kvstore.store = "inmemory";
        };
      };

      compactor = {
        retention_enabled = true;
      };
      limits_config = {
        retention_period = "720h"; # 30 days
      };

      schema_config.configs = [
        {
          from = "2020-10-24";
          store = "boltdb-shipper";
          object_store = "filesystem";
          schema = "v11";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];

      ruler = {
        # TODO switch to s3 backend
        storage = {
          type = "local";
          local = {
            directory = "rules";
          };
        };
        rule_path = "rules";
        enable_api = true;
        alertmanager_url = "https://alertmanager.li7g.com";
        alertmanager_client = {
          basic_auth_username = "alertmanager";
          basic_auth_password = "$ALERTMANAGER_PASSWORD";
        };
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
    owner = config.users.users.nginx.name;
  };
  sops.secrets."loki_hashed_password" = {
    sopsFile = config.sops-file.terraform;
    restartUnits = ["nginx.service"];
  };
  sops.secrets."alertmanager_password" = {
    sopsFile = config.sops-file.get "terraform/infrastructure.yaml";
    restartUnits = ["loki.service"];
  };
  sops.secrets."minio_loki_key_id" = {
    sopsFile = config.sops-file.terraform;
    restartUnits = ["loki.service"];
  };
  sops.secrets."minio_loki_access_key" = {
    sopsFile = config.sops-file.terraform;
    restartUnits = ["loki.service"];
  };
}
