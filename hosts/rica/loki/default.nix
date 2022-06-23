{ config, ... }:

let
  cfg = config.hosts.rica;
in
{
  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;
      server.http_listen_port = cfg.ports.loki;

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
        retention_period = "336h"; # 14 days
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
    };
  };
  security.acme.certs."main".extraDomainNames = [
    "loki.li7g.com"
    "loki.zt.li7g.com"
  ];
  services.nginx = {
    virtualHosts."loki.li7g.com" = {
      forceSSL = true;
      useACMEHost = "main";
      serverAliases = [
        "loki.zt.li7g.com" # for internal connection
      ];
      locations."/" = {
        proxyPass = "http://localhost:${toString cfg.ports.loki}";
        extraConfig = ''
          auth_basic "loki";
          auth_basic_user_file ${config.sops.templates."loki-auth-file".path};
        '';
      };
    };
  };
  sops.templates."loki-auth-file" = {
    content = ''
      loki:${config.sops.placeholder."loki/hashed-password"}
    '';
    owner = "nginx";
  };
  sops.secrets."loki/hashed-password".sopsFile = config.sops.secretsDir + /rica.yaml;
}
