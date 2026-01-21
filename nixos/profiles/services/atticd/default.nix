{ config, ... }:
let
  port = config.ports.atticd;
in
{
  services.atticd = {
    enable = true;
    settings = {
      listen = "[::1]:${toString port}";
      api-endpoint = "https://atticd.endpoints.li7g.com";
      substituter-endpoint = "https://atticd.li7g.com";
      require-proof-of-possession = false;
      database = {
        url = "postgresql:///atticd";
      };
      storage = {
        type = "s3";
        bucket = "cache-li7g-com";
        region = "us-east-1";
        endpoint = "https://${config.lib.self.data.r2_s3_api_url}";
      };
      chunking = {
        nar-size-threshold = 131072;
        min-size = 16384;
        avg-size = 65536;
        max-size = 262144;
      };
      garbage-collection = {
        default-retention-period = "2 weeks";
      };
    };
    environmentFile = config.sops.templates."atticd-env".path;
  };
  services.nginx.virtualHosts."atticd.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    serverAliases = [ "api.atticd.*" ];
    locations."/" = {
      proxyPass = "http://[::1]:${toString port}";
      extraConfig = ''
        client_max_body_size 4G;
      '';
    };
  };
  services.postgresql.ensureDatabases = [ "atticd" ];
  services.postgresql.ensureUsers = [
    {
      name = "atticd";
      ensureDBOwnership = true;
    }
  ];
  sops.templates."atticd-env".content = ''
    AWS_ACCESS_KEY_ID=${config.sops.placeholder."r2_cache_key_id"}
    AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."r2_cache_access_key"}
    ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64=${config.sops.placeholder."atticd_rs256_secret_base64"}
  '';
  sops.secrets."r2_cache_key_id" = {
    terraformOutput.enable = true;
    restartUnits = [ "atticd.service" ];
  };
  sops.secrets."r2_cache_access_key" = {
    terraformOutput.enable = true;
    restartUnits = [ "atticd.service" ];
  };
  sops.secrets."atticd_rs256_secret_base64" = {
    terraformOutput.enable = true;
    restartUnits = [ "atticd.service" ];
  };
}
