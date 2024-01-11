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
        region = data.b2_s3_region;
        bucket = data.b2_attic_store_bucket_name;
        endpoint = data.b2_s3_api_url;
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
    terraformOutput.enable = true;
    restartUnits = ["atticd.service"];
  };
  sops.secrets."b2_attic_store_key_id" = {
    terraformOutput.enable = true;
    restartUnits = ["atticd.service"];
  };
  sops.secrets."b2_attic_store_access_key" = {
    terraformOutput.enable = true;
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
      inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
      locations."/".proxyPass = "http://localhost:${toString config.ports.atticd}";
    };
  };
}
