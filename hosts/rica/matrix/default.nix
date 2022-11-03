{ config, lib, pkgs, ... }:

let
  cfg = config.hosts.rica;
in
{
  services.matrix-synapse = {
    enable = true;
    withJemalloc = true;
    settings = {
      server_name = "li7g.com";
      public_baseurl = "https://matrix.li7g.com";

      database = {
        name = "psycopg2";
        args = {
          # local database
          database = "matrix-synapse";
        };
      };

      # trust the default key server matrix.org
      suppress_key_server_warning = true;

      enable_search = true;
      dynamic_thumbnails = true;
      allow_public_rooms_over_federation = true;

      enable_registration = true;
      registration_requires_token = true;
      registrations_require_3pid = [
        "email"
      ];

      listeners = [{
        bind_addresses = [ "127.0.0.1" ];
        port = cfg.ports.matrix.http;
        tls = false;
        type = "http";
        x_forwarded = true;
        resources = [{
          compress = true;
          names = [ "client" "federation" ];
        }];
      }];
    };
    extraConfigFiles = [
      # configurations with secrets
      config.sops.templates."synapse-extra-config".path
    ];
  };


  # copy singing key to signing key path
  systemd.services.matrix-synapse.serviceConfig.ExecStartPre =
    lib.mkBefore [
      ("+" + (pkgs.writeShellScript "matrix-synapse-fix-permissions" ''
        cp "${config.sops.secrets."synapse/signing-key".path}" "${config.services.matrix-synapse.settings.signing_key_path}"
        chown matrix-synapse:matrix-synapse "${config.services.matrix-synapse.settings.signing_key_path}"
      ''))
    ];

  sops.templates."synapse-extra-config" = {
    owner = "matrix-synapse";
    content = builtins.toJSON {
      email = {
        smtp_host = "smtp.zt.li7g.com";
        smtp_user = "matrix@li7g.com";
        notif_from = "matrix@li7g.com";
        force_tls = true;
        smtp_pass = config.sops.placeholder."mail_password";
      };
      # TODO make package for the provider or host a standalone media repo
      # media_storage_providers = [
      #   {
      #     module = "s3_storage_provider.S3StorageProviderBackend";
      #     store_remote = true;
      #     config = {
      #       bucket = "synapse-media";
      #       endpoint_url = "minio.li7g.com";
      #       access_key_id = config.sops.placeholder."minio_synapse_media_key_id";
      #       secret_access_key = config.sops.placeholder."minio_synapse_media_access_key";
      #     };
      #   }
      # ];
    };
  };

  sops.secrets."synapse/signing-key" = {
    sopsFile = config.sops.secretsDir + /hosts/rica.yaml;
    owner = "matrix-synapse";
    restartUnits = [ "matrix-synapse.service" ];
  };
  sops.secrets."mail_password" = {
    sopsFile = config.sops.secretsDir + /terraform/common.yaml;
    restartUnits = [ "matrix-synapse.service" ];
  };
  sops.secrets."minio_synapse_media_key_id" = {
    sopsFile = config.sops.secretsDir + /terraform/hosts/rica.yaml;
    restartUnits = [ "matrix-synapse.service" ];
  };
  sops.secrets."minio_synapse_media_access_key" = {
    sopsFile = config.sops.secretsDir + /terraform/hosts/rica.yaml;
    restartUnits = [ "matrix-synapse.service" ];
  };

  systemd.services.matrix-synapse.after = [ "postgresql.service" ];
  services.postgresql = {
    ensureDatabases = [ "matrix-synapse" ];
    ensureUsers = [
      {
        name = "matrix-synapse";
        ensurePermissions = {
          "DATABASE \"matrix-synapse\"" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  services.nginx.virtualHosts."matrix.*" = {
    forceSSL = true;
    useACMEHost = "main";
    locations."/_matrix" = {
      proxyPass = "http://127.0.0.1:${toString cfg.ports.matrix.http}";
    };
    locations."/" = {
      root = pkgs.element-web-li7g-com;
    };
  };
}
