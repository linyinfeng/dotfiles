{
  config,
  lib,
  pkgs,
  ...
}:
let
  element-web-config = pkgs.runCommand "element-web-config" { } ''
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
        registrations_require_3pid = [ "email" ];

        media_retention = {
          # no retention for local media to keep stickers
          # local_media_lifetime = "180d";
          remote_media_lifetime = "14d";
        };

        listeners = [
          {
            bind_addresses = [ "127.0.0.1" ];
            port = config.ports.matrix;
            tls = false;
            type = "http";
            x_forwarded = true;
            resources = [
              {
                compress = true;
                names = [
                  "client"
                  "federation"
                ];
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
        email = {
          smtp_host = "smtp.li7g.com";
          smtp_user = "matrix@li7g.com";
          notif_from = "matrix@li7g.com";
          force_tls = true;
          smtp_pass = config.sops.placeholder."mail_password";
        };
      };
    };

    systemd.services.matrix-synapse = {
      # copy signing key to signing key path
      serviceConfig.ExecStartPre = lib.mkBefore [
        (
          "+"
          + (pkgs.writeShellScript "matrix-synapse-fix-permissions" ''
            cp "${
              config.sops.secrets."synapse_signing_key".path
            }" "${config.services.matrix-synapse.settings.signing_key_path}"
            chown matrix-synapse:matrix-synapse "${config.services.matrix-synapse.settings.signing_key_path}"
          '')
        )
      ];
      restartTriggers = [ config.sops.templates."synapse-extra-config".file ];
    };

    systemd.services.matrix-synapse.after = [ "postgresql.service" ];
    services.postgresql = {
      ensureDatabases = [
        "matrix-synapse" # TODO locale problem
      ];
      ensureUsers = [
        {
          name = "matrix-synapse";
          ensureDBOwnership = true;
        }
      ];
    };
  }

  # oidc
  {
    services.matrix-synapse.settings = {
      oidc_providers = [
        {
          allow_existing_users = true;
          idp_id = "pocket_id";
          idp_name = "Pocket ID";
          issuer = "https://id.li7g.com";
          client_id = "6ab75dbc-8cf9-45f5-8a2a-9425e45e58c7";
          client_secret_path = config.sops.secrets."synapse_oidc_pocket_id".path;
          scopes = [
            "openid"
            "profile"
          ];
          user_mapping_provider = {
            config = {
              localpart_template = "{{ user.preferred_username }}";
              display_name_template = "{{ user.name }}";
            };
          };
        }
      ];
    };
    sops.secrets."synapse_oidc_pocket_id" = {
      predefined.enable = true;
      owner = config.users.users.matrix-synapse.name;
      restartUnits = [ "matrix-synapse.service" ];
    };
  }

  # mautrix-telegram
  {
    services.mautrix-telegram = {
      enable = true;
      registerToSynapse = false; # manual registration for flexible deployment
      environmentFile = config.sops.templates."mautrix-telegram-config".path;
      serviceDependencies = [ "matrix-synapse.service" ];
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
          # app id and hash from Fedora telegram-desktop
          api_id = 611335;
          api_hash = "d524b414d21f4d37f08684c1df41ac9c";
          device_info = {
            app_version = pkgs.telegram-desktop.version;
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
      restartTriggers = [ config.sops.templates."mautrix-telegram-config".file ];
    };

    sops.templates."mautrix-telegram-config".content = ''
      MAUTRIX_TELEGRAM_APPSERVICE_AS_TOKEN=${
        config.sops.placeholder."mautrix_telegram_appservice_as_token"
      }
      MAUTRIX_TELEGRAM_APPSERVICE_HS_TOKEN=${
        config.sops.placeholder."mautrix_telegram_appservice_hs_token"
      }
      MAUTRIX_TELEGRAM_TELEGRAM_BOT_TOKEN=${config.sops.placeholder."telegram_bot_matrix_bridge"}
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
    sops.secrets."mautrix_telegram_appservice_as_token" = {
      terraformOutput.enable = true;
      restartUnits = [
        "matrix-synapse.service"
        "mautrix-telegram.service"
      ];
    };
    sops.secrets."mautrix_telegram_appservice_hs_token" = {
      terraformOutput.enable = true;
      restartUnits = [
        "matrix-synapse.service"
        "mautrix-telegram.service"
      ];
    };
    sops.secrets."telegram_bot_matrix_bridge" = {
      predefined.enable = true;
      restartUnits = [ "mautrix-telegram.service" ];
    };

    systemd.services.mautrix-telegram.after = [ "postgresql.service" ];
    services.postgresql = {
      ensureDatabases = [ "mautrix-telegram" ];
      ensureUsers = [
        {
          name = "mautrix-telegram";
          ensureDBOwnership = true;
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
      terraformOutput.enable = true;
      restartUnits = [ "matrix-synapse.service" ];
    };
    sops.secrets."matrix_qq_appservice_hs_token" = {
      terraformOutput.enable = true;
      restartUnits = [ "matrix-synapse.service" ];
    };
  }

  # secrets
  {
    sops.secrets."synapse_signing_key" = {
      predefined.enable = true;
      owner = "matrix-synapse";
      restartUnits = [ "matrix-synapse.service" ];
    };
    sops.secrets."mail_password" = {
      terraformOutput.enable = true;
      restartUnits = [ "matrix-synapse.service" ];
    };
  }

  # reverse proxy
  {
    services.nginx.virtualHosts."matrix.*" = {
      forceSSL = true;
      inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
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
      inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
      locations."/".root = pkgs.synapse-admin;
    };
  }

  # backup
  { services.restic.backups.b2.paths = [ "/var/lib/matrix-synapse" ]; }
]
