{ config, lib, pkgs, ... }:

let
  element-web-config = pkgs.runCommand "element-web-config" { } ''
    mkdir -p $out
    "${pkgs.jq}/bin/jq" -s ".[0] * .[1]" \
      "${pkgs.element-web}/config.json" \
      ${./mixin-config.json} \
      > $out/config.json
  '';

  yamlFormat = pkgs.formats.yaml { };
in
lib.mkMerge [
  # matrix-synapse
  {
    services.matrix-synapse = {
      enable = true;
      withJemalloc = true;
      plugins = [
        pkgs.nur.repos.linyinfeng.synapse-s3-storage-provider
      ];
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
          port = config.ports.matrix;
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

    sops.templates."synapse-extra-config" = {
      owner = "matrix-synapse";
      content = builtins.toJSON {
        email = {
          smtp_host = "smtp.li7g.com";
          smtp_user = "matrix@li7g.com";
          notif_from = "matrix@li7g.com";
          force_tls = true;
          smtp_pass = config.sops.placeholder."mail_password";
        };
        media_storage_providers = [
          {
            module = "s3_storage_provider.S3StorageProviderBackend";
            store_local = true;
            store_remote = true;
            store_synchronous = true;
            config = {
              bucket = "synapse-media";
              endpoint_url = "https://minio.ts.li7g.com";
              access_key_id = config.sops.placeholder."minio_synapse_media_key_id";
              secret_access_key = config.sops.placeholder."minio_synapse_media_access_key";
            };
          }
        ];
      };
    };

    environment.systemPackages = [
      pkgs.nur.repos.linyinfeng.synapse-s3-storage-provider
    ];

    systemd.services.matrix-synapse = {
      # copy singing key to signing key path
      serviceConfig.ExecStartPre =
        lib.mkBefore [
          ("+" + (pkgs.writeShellScript "matrix-synapse-fix-permissions" ''
            cp "${config.sops.secrets."synapse/signing-key".path}" "${config.services.matrix-synapse.settings.signing_key_path}"
            chown matrix-synapse:matrix-synapse "${config.services.matrix-synapse.settings.signing_key_path}"
          ''))
        ];
      restartTriggers = [
        config.sops.templates."synapse-extra-config".file
      ];
    };
  }

  # mautrix-telegram
  {
    services.mautrix-telegram = {
      enable = true;
      environmentFile = config.sops.templates."mautrix-telegram-config".path;
      serviceDependencies = [ "matrix-synapse.service" ];
      settings = {
        homeserver = {
          address = "http://127.0.0.1:${toString config.ports.matrix}";
          domain = "li7g.com";
        };
        appservice = {
          address = "http://127.0.0.1:${toString config.ports.mautrix-telegram-appservice}";
          database = "postgres:///mautrix-telegram?host=/run/postgresql";
          hostname = "127.0.0.1";
          port = config.ports.mautrix-telegram-appservice;
          provisioning.enabled = false;
        };
        bridge = {
          public_portals = true;
          delivery_error_reports = true;
          animated_sticker = {
            target = "webp"; # require ffmpeg in path
            convert_from_webm = true;
          };
          permissions = {
            "*" = "relaybot";
            "@yinfeng:li7g.com" = "admin";
          };
          encryption = {
            allow = true;
          };
        };
        telegram = {
          # app id and hash from Fedora tdesktop
          api_id = 611335;
          api_hash = "d524b414d21f4d37f08684c1df41ac9c";
          device_info = {
            app_version = pkgs.tdesktop.version;
          };
        };
        logging = {
          loggers = {
            mau.level = "WARNING";
            telethon.level = "WARNING";
          };
        };
      };
    };

    systemd.services.mautrix-telegram = {
      path = with pkgs; [
        ffmpeg-full # for animated sticker conversion
      ];
      restartTriggers = [
        config.sops.templates."mautrix-telegram-config".file
      ];
    };

    sops.templates."mautrix-telegram-config".content = ''
      MAUTRIX_TELEGRAM_APPSERVICE_AS_TOKEN=${config.sops.placeholder."mautrix_telegram_appservice_as_token"}
      MAUTRIX_TELEGRAM_APPSERVICE_HS_TOKEN=${config.sops.placeholder."mautrix_telegram_appservice_hs_token"}
      MAUTRIX_TELEGRAM_TELEGRAM_BOT_TOKEN=${config.sops.placeholder."telegram-bot/matrix-bridge"}
    '';

    services.matrix-synapse.settings.app_service_config_files = [
      config.sops.templates."mautrix-telegram-registration".path
    ];
    systemd.services.matrix-synapse.restartTriggers = [
      config.sops.templates."mautrix-telegram-registration".file
    ];
    sops.templates."mautrix-telegram-registration" = {
      owner = "matrix-synapse";
      content = builtins.toJSON {
        id = "mautrix-telegram";
        url = "http://localhost:${toString config.ports.mautrix-telegram-appservice}";
        as_token = config.sops.placeholder."mautrix_telegram_appservice_as_token";
        hs_token = config.sops.placeholder."mautrix_telegram_appservice_hs_token";
        sender_localpart = "mautrix-telegram";
        rate_limited = false;
        de.sorunome.msc2409.push_ephemeral = true;
        push_ephemeral = true;
        namespaces = {
          users = [
            {
              exclusive = true;
              regex = "@telegram_.*:li7g\\.com";
            }
            {
              exclusive = true;
              regex = "@telegrambot:li7g\.com";
            }
          ];
          rooms = [ ];
          aliases = [
            {
              exclusive = true;
              regex = "\\#telegram_.*:li7g\\.com";
            }
          ];
        };
      };
    };
  }

  # matrix-qq
  {
    # the matrix-qq service is hosted on another host

    services.matrix-synapse.settings.app_service_config_files = [
      config.sops.templates."matrix-qq-registration".path
    ];
    systemd.services.matrix-synapse.restartTriggers = [
      config.sops.templates."matrix-qq-registration".file
    ];
    sops.templates."matrix-qq-registration" = {
      owner = "matrix-synapse";
      content = builtins.toJSON {
        id = "qq";
        url = "https://matrix-qq.ts.li7g.com";
        as_token = config.sops.placeholder."matrix_qq_appservice_as_token";
        hs_token = config.sops.placeholder."matrix_qq_appservice_hs_token";
        sender_localpart = "qq";
        rate_limited = false;
        de.sorunome.msc2409.push_ephemeral = true;
        push_ephemeral = true;
        namespaces = {
          users = [
            {
              exclusive = true;
              regex = "^@qqbot:li7g\.com$";
            }
            {
              exclusive = true;
              regex = "^@_qq_.*:li7g\.com$";
            }
          ];
        };
      };
    };
  }

  # secrets
  {
    sops.secrets."synapse/signing-key" = {
      sopsFile = config.sops-file.host;
      owner = "matrix-synapse";
      restartUnits = [ "matrix-synapse.service" ];
    };
    sops.secrets."mail_password" = {
      sopsFile = config.sops-file.get "terraform/common.yaml";
      restartUnits = [ "matrix-synapse.service" ];
    };
    sops.secrets."minio_synapse_media_key_id" = {
      sopsFile = config.sops-file.terraform;
      restartUnits = [ "matrix-synapse.service" ];
    };
    sops.secrets."minio_synapse_media_access_key" = {
      sopsFile = config.sops-file.terraform;
      restartUnits = [ "matrix-synapse.service" ];
    };
    sops.secrets."mautrix_telegram_appservice_as_token" = {
      sopsFile = config.sops-file.terraform;
      restartUnits = [ "matrix-synapse.service" "mautrix-telegram.service" ];
    };
    sops.secrets."mautrix_telegram_appservice_hs_token" = {
      sopsFile = config.sops-file.terraform;
      restartUnits = [ "matrix-synapse.service" "mautrix-telegram.service" ];
    };
    sops.secrets."telegram-bot/matrix-bridge" = {
      sopsFile = config.sops-file.host;
      restartUnits = [ "mautrix-telegram.service" ];
    };
    sops.secrets."matrix_qq_appservice_as_token" = {
      sopsFile = config.sops-file.terraform;
      restartUnits = [ "matrix-synapse.service" "matrix-qq.service" ];
    };
    sops.secrets."matrix_qq_appservice_hs_token" = {
      sopsFile = config.sops-file.terraform;
      restartUnits = [ "matrix-synapse.service" "matrix-qq.service" ];
    };
  }

  # database
  {
    systemd.services.matrix-synapse.after = [ "postgresql.service" ];
    systemd.services.mautrix-telegram.after = [ "postgresql.service" ];
    services.postgresql = {
      ensureDatabases = [
        "matrix-synapse" # TODO locale problem
        "mautrix-telegram"
        "matrix-qq"
      ];
      ensureUsers = [
        {
          name = "matrix-synapse";
          ensurePermissions = {
            "DATABASE \"matrix-synapse\"" = "ALL PRIVILEGES";
          };
        }
        {
          name = "mautrix-telegram";
          ensurePermissions = {
            "DATABASE \"mautrix-telegram\"" = "ALL PRIVILEGES";
          };
        }
      ];
    };
  }

  # reverse proxy
  {
    services.nginx.virtualHosts."matrix.*" = {
      forceSSL = true;
      useACMEHost = "main";
      locations."/_matrix" = {
        proxyPass = "http://127.0.0.1:${toString config.ports.matrix}";
      };
      locations."/" = {
        root = pkgs.element-web;
      };
      locations."/config.json" = {
        root = element-web-config;
      };
    };
    passthru.element-web-config = element-web-config;
  }

]
