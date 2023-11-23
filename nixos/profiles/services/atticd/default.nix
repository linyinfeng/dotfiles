{config, ...}: let
  data = config.lib.self.data;
in {
  services.atticd = {
    enable = true;
    credentialsFile = config.sops.templates."atticd-credentials".path;
    settings = {
      listen = "[::]:${toString config.ports.atticd}";
      api-endpoint = "https://attic.li7g.com/";

      database.url = "postgresql://atticd?host=/run/postgresql";
      storage = {
        type = "s3";
        region = data.attic_store_region;
        bucket = data.attic_store_bucket_name;
        endpoint = data.attic_store_s3_url;
      };
      chunking = {
        # disable chunking
        nar-size-threshold = 0;
        min-size = 16384;
        avg-size = 65536;
        max-size = 262144;
      };
      compression = {
        type = "zstd";
      };
      garbage-collection = {
        interval = "12 hours";
        default-retention-period = "2 weeks";
      };
    };
  };

  sops.templates."atticd-credentials".content = ''
    ATTIC_SERVER_TOKEN_HS256_SECRET_BASE64=${config.sops.placeholder."atticd_token_hs256_secret_base64"}
    AWS_ACCESS_KEY_ID=${config.sops.placeholder."b2_attic_store_key_id"}
    AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."b2_attic_store_access_key"}
  '';

  sops.secrets."atticd_token_hs256_secret_base64" = {
    sopsFile = config.sops-file.terraform;
    restartUnits = ["atticd.service"];
  };
  sops.secrets."b2_attic_store_key_id" = {
    sopsFile = config.sops-file.terraform;
    restartUnits = ["atticd.service"];
  };
  sops.secrets."b2_attic_store_access_key" = {
    sopsFile = config.sops-file.terraform;
    restartUnits = ["atticd.service"];
  };

  services.postgresql.ensureDatabases = ["atticd"];
  services.postgresql.ensureUsers = [
    {
      name = "atticd";
      ensureDBOwnership = true;
    }
  ];

  services.nginx = {
    virtualHosts."attic.*" = {
      serverAliases = ["attic-upload.*"];
      forceSSL = true;
      useACMEHost = "main";
      locations."/".proxyPass = "http://localhost:${toString config.ports.atticd}";
    };
  };
}
