{
  config,
  lib,
  pkgs,
  ...
}: let
  serviceNames = [
    "mastodon-streaming"
    "mastodon-web"
    "mastodon-sidekiq"
    "mastodon-media-auto-remove"
  ];
  serviceUnits = lib.lists.map (n: "${n}.service") serviceNames;
in
  lib.mkMerge [
    {
      services.mastodon = {
        enable = true;
        enableUnixSocket = true;
        database = {
          host = "/run/postgresql";
          name = "mastodon";
          user = "mastodon";
        };
        mediaAutoRemove = {
          enable = true;
          olderThanDays = 60;
          startAt = "daily";
        };
        smtp = {
          authenticate = true;
          host = "smtp.li7g.com";
          port = config.ports.smtp-starttls;
          user = "mastodon@li7g.com";
          fromAddress = "mastodon@li7g.com";
          # type is null or path, add a leading /
          passwordFile = "/$CREDENTIALS_DIRECTORY/mail-password";
        };
        localDomain = "li7g.com";
        configureNginx = false;
        extraConfig = {
          WEB_DOMAIN = "mastodon.li7g.com";
          ALTERNATE_DOMAINS = lib.concatStringsSep "," [
            "social.li7g.com"
          ];
          S3_ENABLED = "true";
          S3_BUCKET = config.lib.self.data.mastodon_media_bucket_name;
          S3_REGION = config.lib.self.data.mastodon_media_region;
          S3_ENDPOINT = config.lib.self.data.mastodon_media_url;
          S3_ALIAS_HOST = "b2.li7g.com/file/${config.lib.self.data.mastodon_media_bucket_name}";
        };
      };
      users.users.${config.services.mastodon.user}.shell = pkgs.bash;
      systemd.services =
        lib.listToAttrs
        (lib.lists.map
          (serviceName:
            lib.nameValuePair serviceName {
              serviceConfig.EnvironmentFile = [
                config.sops.templates."mastodon-extra-env".path
              ];
              restartTriggers = [
                config.sops.templates."mastodon-extra-env".file
              ];
            })
          serviceNames)
        // {
          mastodon-init-dirs.serviceConfig.LoadCredential = [
            "mail-password:${config.sops.secrets."mail_password".path}"
          ];
        };
      sops.templates."mastodon-extra-env".content = ''
        AWS_ACCESS_KEY_ID=${config.sops.placeholder."b2_mastodon_media_key_id"}
        AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."b2_mastodon_media_access_key"}
      '';
      services.postgresql.ensureDatabases = ["mastodon"];
      services.postgresql.ensureUsers = [
        {
          name = "mastodon";
          ensurePermissions = {
            "DATABASE mastodon" = "ALL PRIVILEGES";
          };
        }
      ];
      sops.secrets."mail_password" = {
        sopsFile = config.sops-file.get "terraform/common.yaml";
        restartUnits = ["mastodon-init-dirs.service"];
      };
      sops.secrets."b2_mastodon_media_key_id" = {
        sopsFile = config.sops-file.terraform;
        restartUnits = serviceUnits;
      };
      sops.secrets."b2_mastodon_media_access_key" = {
        sopsFile = config.sops-file.terraform;
        restartUnits = serviceUnits;
      };
    }

    # reverse proxy
    {
      services.nginx.virtualHosts."mastodon.*" = {
        forceSSL = true;
        useACMEHost = "main";
        serverAliases = ["social.*"];
        root = "${config.services.mastodon.package}/public/";
        locations."/system/".alias = "/var/lib/mastodon/public-system/";
        locations."/" = {
          tryFiles = "$uri @proxy";
        };
        locations."@proxy" = {
          proxyPass = "http://unix:/run/mastodon-web/web.socket";
          proxyWebsockets = true;
        };
        locations."/api/v1/streaming/" = {
          proxyPass = "http://unix:/run/mastodon-streaming/streaming.socket";
          proxyWebsockets = true;
        };
      };
      systemd.services.nginx.serviceConfig.SupplementaryGroups = [
        config.services.mastodon.group
      ];
    }

    # backup
    {
      services.restic.backups.b2.paths = [
        "/var/lib/mastodon"
      ];
    }
  ]
