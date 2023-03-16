{ config, ... }:

{
  services.atticd = {
    enable = true;
    credentialsFile = config.sops.templates."atticd-credentials".path;
    settings = {
      listen = "[::]:${toString config.ports.atticd}";
      api-endpoint = "https://attic.li7g.com";

      database.url = "postgresql://atticd?host=/run/postgresql";
      storage = {
        type = "s3";
        region = config.lib.self.data.atticd_region;
        bucket = config.lib.self.data.atticd_bucket_name;
        endpoint = config.lib.self.data.atticd_url;
      };
      chunking = {
        # chunking is disabled entirely
        # nar-size-threshold = 65536;
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
    AWS_ACCESS_KEY_ID=${config.sops.placeholder."b2_atticd_key_id"}
    AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."b2_atticd_access_key"}
  '';

  sops.secrets."atticd_token_hs256_secret_base64" = {
    sopsFile = config.sops-file.terraform;
    restartUnits = ["atticd.service"];
  };
  sops.secrets."b2_atticd_key_id" = {
    sopsFile = config.sops-file.terraform;
    restartUnits = ["atticd.service"];
  };
  sops.secrets."b2_atticd_access_key" = {
    sopsFile = config.sops-file.terraform;
    restartUnits = ["atticd.service"];
  };

  services.postgresql.ensureDatabases = ["atticd"];
  services.postgresql.ensureUsers = [
    {
      name = "atticd";
      ensurePermissions = {
        "DATABASE atticd" = "ALL PRIVILEGES";
      };
    }
  ];

  services.nginx = {
    virtualHosts."attic.*" = {
      forceSSL = true;
      useACMEHost = "main";
      locations."/".proxyPass = "http://localhost:${toString config.ports.atticd}";
    };
  };
}
