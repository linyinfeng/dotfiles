{
  config,
  lib,
  pkgs,
  ...
}: let
  element-web-config = pkgs.runCommand "element-web-config" {} ''
    mkdir -p $out
    "${pkgs.jq}/bin/jq" -s ".[0] * .[1]" \
      "${pkgs.element-web}/config.json" \
      ${./mixin-config.json} \
      > $out/config.json
  '';
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
          admin_contact = "mailto:lin.yinfeng@outlook.com";

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

          media_retention = {
            # no retention for local media to keep stickers
            # local_media_lifetime = "180d";
            remote_media_lifetime = "14d";
          };

          listeners = [
            {
              bind_addresses = ["127.0.0.1"];
              port = config.ports.matrix;
              tls = false;
              type = "http";
              x_forwarded = true;
              resources = [
                {
                  compress = true;
                  names = ["client" "federation"];
                }
              ];
            }
          ];
        };
        extraConfigFiles = [
          # configurations with secrets
          config.sops.templates."synapse-extra-config".path
        ];
      };

      sops.templates."synapse-extra-config" = {
        owner = "matrix-synapse";
        content = builtins.toJSON {
          registration_shared_secret = config.sops.placeholder."matrix_registration_shared_secret";
          email = {
            smtp_host = "smtp.li7g.com";
            smtp_user = "matrix@li7g.com";
            notif_from = "matrix@li7g.com";
            force_tls = true;
            smtp_pass = config.sops.placeholder."mail_password";
          };
          media_storage_providers = [
            # as backup of all local media
            {
              module = "s3_storage_provider.S3StorageProviderBackend";
              store_local = true;
              store_remote = false;
              store_synchronous = true;
              config = {
                bucket = config.lib.self.data.synapse_media_bucket_name;
                endpoint_url = config.lib.self.data.synapse_media_url;
                access_key_id = config.sops.placeholder."b2_synapse_media_key_id";
                secret_access_key = config.sops.placeholder."b2_synapse_media_access_key";
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
        serviceConfig.ExecStartPre = lib.mkBefore [
          ("+"
            + (pkgs.writeShellScript "matrix-synapse-fix-permissions" ''
              cp "${config.sops.secrets."synapse/signing-key".path}" "${config.services.matrix-synapse.settings.signing_key_path}"
              chown matrix-synapse:matrix-synapse "${config.services.matrix-synapse.settings.signing_key_path}"
            ''))
        ];
        restartTriggers = [
          config.sops.templates."synapse-extra-config".file
        ];
      };

      systemd.services.matrix-synapse.after = ["postgresql.service"];
      services.postgresql = {
        ensureDatabases = [
          "matrix-synapse" # TODO locale problem
        ];
        ensureUsers = [
          {
            name = "matrix-synapse";
            ensurePermissions = {
              "DATABASE \"matrix-synapse\"" = "ALL PRIVILEGES";
            };
          }
        ];
      };
    }

    # mautrix-telegram
    {
      services.mautrix-telegram = {
        enable = true;
        environmentFile = config.sops.templates."mautrix-telegram-config".path;
        serviceDependencies = ["matrix-synapse.service"];
        settings = {
          homeserver = {
            address = "http://127.0.0.1:${toString config.ports.matrix}";
            domain = "li7g.com";
          };
          appservice = {
            id = "telegram";
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
          id = "telegram";
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
            rooms = [];
            aliases = [
              {
                exclusive = true;
                regex = "\\#telegram_.*:li7g\\.com";
              }
            ];
          };
        };
      };
      sops.secrets."mautrix_telegram_appservice_as_token" = {
        sopsFile = config.sops-file.terraform;
        restartUnits = ["matrix-synapse.service" "mautrix-telegram.service"];
      };
      sops.secrets."mautrix_telegram_appservice_hs_token" = {
        sopsFile = config.sops-file.terraform;
        restartUnits = ["matrix-synapse.service" "mautrix-telegram.service"];
      };
      sops.secrets."telegram-bot/matrix-bridge" = {
        sopsFile = config.sops-file.host;
        restartUnits = ["mautrix-telegram.service"];
      };

      systemd.services.mautrix-telegram.after = ["postgresql.service"];
      services.postgresql = {
        ensureDatabases = [
          "mautrix-telegram"
        ];
        ensureUsers = [
          {
            name = "mautrix-telegram";
            ensurePermissions = {
              "DATABASE \"mautrix-telegram\"" = "ALL PRIVILEGES";
            };
          }
        ];
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

      sops.secrets."matrix_qq_appservice_as_token" = {
        sopsFile = config.sops-file.terraform;
        restartUnits = ["matrix-synapse.service" "matrix-qq.service"];
      };
      sops.secrets."matrix_qq_appservice_hs_token" = {
        sopsFile = config.sops-file.terraform;
        restartUnits = ["matrix-synapse.service" "matrix-qq.service"];
      };
    }

    # matrix-chatgpt-bot
    {
      systemd.services."matrix-chatgpt-bot" = {
        script = ''
          ${pkgs.nur.repos.linyinfeng.matrix-chatgpt-bot}/bin/matrix-chatgpt-bot
        '';
        serviceConfig = {
          Restart = "on-failure";
          DynamicUser = true;
          StateDirectory = "matrix-chatgpt-bot";
          EnvironmentFile = [
            config.sops.templates."matrix-chatgpt-extra-env".path
          ];
        };
        environment = {
          DATA_PATH = "/var/lib/matrix-chatgpt-bot";

          CHATGPT_CONTEXT = "thread";
          CHATGPT_API_MODEL = "gpt-3.5-turbo";
          # Update knowledge cutoff date accroding to https://platform.openai.com/docs/models
          CHATGPT_PROMPT_PREFIX = ''
            You are ChatGPT, a large language model trained by OpenAI. Answer as concisely as possible.
            Knowledge cutoff: 2021-09
          '';

          KEYV_BACKEND = "file";
          KEYV_URL = "";
          KEYV_BOT_ENCRYPTION = "false";
          KEYV_BOT_STORAGE = "true";

          MATRIX_HOMESERVER_URL = "https://matrix.li7g.com";
          MATRIX_BOT_USERNAME = "@chatgptbot:li7g.com";

          MATRIX_DEFAULT_PREFIX = "!chatgpt";
          MATRIX_DEFAULT_PREFIX_REPLY = "false";

          # MATRIX_BLACKLIST = "";
          # MATRIX_WHITELIST = "@yinfeng:li7g.com";
          # MATRIX_ROOM_BLACKLIST = "";
          MATRIX_ROOM_WHITELIST = lib.concatStringsSep " " [
            "!clkyAURLHpXBYpcfSE:li7g.com" # public - #njulug:li7g.com
            "!ZcyNnUjSsEKYLfgpBu:li7g.com" # private - #chatgpt:li7g.com
            "!MPQSzGQmrbZGaDnPaL:li7g.com" # private - #apartment-five:li7g.com
            "!cacbMwUwsLZ6GKac:nichi.co" # public - #zh-cn:nixos.org
          ];

          MATRIX_AUTOJOIN = "true";
          MATRIX_ENCRYPTION = "true";
          MATRIX_THREADS = "true";
          MATRIX_PREFIX_DM = "false";
          MATRIX_RICH_TEXT = "true";
        };
        # on same machine
        after = ["matrix-synapse.service"];
        wantedBy = ["multi-user.target"];
      };
      sops.templates."matrix-chatgpt-extra-env".content = ''
        OPENAI_API_KEY=${config.sops.placeholder."chatgpt-bot/openai-api-key"}
        MATRIX_BOT_PASSWORD=${config.sops.placeholder."chatgpt-bot/matrix-password"}
        MATRIX_ACCESS_TOKEN=${config.sops.placeholder."chatgpt-bot/matrix-access-token"}
      '';
      sops.secrets."chatgpt-bot/openai-api-key" = {
        sopsFile = config.sops-file.host;
        restartUnits = ["matrix-chatgpt-bot.service"];
      };
      sops.secrets."chatgpt-bot/matrix-password" = {
        sopsFile = config.sops-file.host;
        restartUnits = ["matrix-chatgpt-bot.service"];
      };
      sops.secrets."chatgpt-bot/matrix-access-token" = {
        sopsFile = config.sops-file.host;
        restartUnits = ["matrix-chatgpt-bot.service"];
      };
    }

    # secrets
    {
      sops.secrets."synapse/signing-key" = {
        sopsFile = config.sops-file.host;
        owner = "matrix-synapse";
        restartUnits = ["matrix-synapse.service"];
      };
      sops.secrets."mail_password" = {
        sopsFile = config.sops-file.get "terraform/common.yaml";
        restartUnits = ["matrix-synapse.service"];
      };
      sops.secrets."matrix_registration_shared_secret" = {
        sopsFile = config.sops-file.terraform;
        restartUnits = ["matrix-synapse.service"];
      };
      sops.secrets."b2_synapse_media_key_id" = {
        sopsFile = config.sops-file.terraform;
        restartUnits = ["matrix-synapse.service"];
      };
      sops.secrets."b2_synapse_media_access_key" = {
        sopsFile = config.sops-file.terraform;
        restartUnits = ["matrix-synapse.service"];
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
        locations."/_synapse" = {
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

    # synapse admin
    {
      services.nginx.virtualHosts."synapse-admin.*" = {
        forceSSL = true;
        useACMEHost = "main";
        locations."/".root = pkgs.synapse-admin;
      };
    }

    # backup
    {
      services.restic.backups.b2.paths = [
        "/var/lib/matrix-synapse/homeserver.signing.key"
      ];
    }
  ]
