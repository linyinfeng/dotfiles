{
  config,
  lib,
  ...
}:
{
  imports = [
    ./_cache.nix
    ./_channel.nix
    ./_queue-runner.nix
  ];

  config = lib.mkMerge [
    {
      services.nginx.virtualHosts."hydra.*" = {
        forceSSL = true;
        inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
        serverAliases = [ "hydra-proxy.*" ];
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.ports.hydra}";
          extraConfig = ''
            # Catalyst (via ProxyBase) builds the asset base from X-Request-Base; $host drops the port
            proxy_set_header X-Request-Base $hydra_base;
          '';
        };
      };
      services.nginx.appendHttpConfig = ''
        # the asset base follows the real host; the split reaches this listener on
        # ports.https-internal, so the client came in on ports.https-alternative
        map $server_port $hydra_base {
          "${toString config.ports.https-internal}" "$scheme://$host:${toString config.ports.https-alternative}/";
          default "$scheme://$host/";
        }
      '';
      services.hydra = {
        enable = true;
        listenHost = "127.0.0.1";
        port = config.ports.hydra;
        hydraURL = "https://hydra.li7g.com";
        notificationSender = "hydra@li7g.com";
        useSubstitutes = true;
        smtpHost = "smtp.li7g.com";
        evaluatorSettings.max_concurrent_evals = 1;
        extraEnv = lib.mkIf config.networking.fw-proxy.enable config.networking.fw-proxy.environment;
        extraConfig = ''
          Include "${config.sops.templates."hydra-extra-config".path}"

          # nix-eval-jobs budget: one NixOS/HM attribute alone peaks near 6 GiB
          evaluator_workers = 1
          evaluator_max_memory_size = 16384

          <githubstatus>
            jobs = .*
            excludeBuildFromContext = 1
          </githubstatus>
        '';
      };
      # allow evaluator to access nix-access-tokens
      systemd.services.hydra-evaluator.serviceConfig.SupplementaryGroups = [
        config.users.groups.nix-access-tokens.name
      ];
      sops.templates."hydra-extra-config" = {
        group = "hydra";
        mode = "440";
        content = ''
          <github_authorization>
            linyinfeng = Bearer ${config.sops.placeholder."github_token_nano"}
            littlenano = Bearer ${config.sops.placeholder."github_token_nano"}
          </github_authorization>
        '';
      };
      nix.settings.secret-key-files = [ "${config.sops.secrets."cache_li7g_com_key".path}" ];
      nix.settings.allowed-uris = [
        "github:"
        "gitlab:"
        "https://github.com/"
        "https://gitlab.com/"
        "https://git.sr.ht/"
        "git+https://github.com/"
        "git+https://gitlab.freedesktop.org/"
      ];
      sops.secrets."github_token_nano" = {
        predefined.enable = true;
        restartUnits = [
          "hydra-evaluator.service"
          "hydra-queue-runner.service"
        ];
      };
      sops.secrets."cache_li7g_com_key" = {
        predefined.enable = true;
        restartUnits = [ "nix-daemon.service" ];
      };
      nix.settings.trusted-users = [ "@hydra" ];
    }

    # {
    #   # store
    #   services.hydra = {
    #     extraConfig = ''
    #       Include "${config.sops.templates."hydra-extra-config".path}"

    #       store_uri = s3://${cacheBucketName}?endpoint=cache-overlay.ts.li7g.com&parallel-compression=true&compression=zstd&secret-key=${
    #         config.sops.secrets."cache_li7g_com_key".path
    #       }
    #       server_store_uri = https://cache.li7g.com?local-nar-cache=${narCache}
    #       binary_cache_public_uri = https://cache.li7g.com
    #     '';
    #   };
    #   systemd.services.hydra-queue-runner.serviceConfig.environmentFile = [
    #     config.sops.templates."hydra-queue-runner-env".path
    #   ];
    #   sops.templates."hydra-queue-runner-env".content = ''
    #     export AWS_ACCESS_KEY_ID=${config.sops.placeholder."r2_cache_key_id"}
    #     export AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."r2_cache_access_key"}
    #     export AWS_EC2_METADATA_DISABLED=true
    #   '';
    #   systemd.tmpfiles.rules = [
    #     "d /var/cache/hydra 0755 hydra hydra -  -"
    #     "d ${narCache}      0775 hydra hydra 1d -"
    #   ];
    #   sops.secrets."r2_cache_key_id" = {
    #     terraformOutput.enable = true;
    #   };
    #   sops.secrets."r2_cache_access_key" = {
    #     terraformOutput.enable = true;
    #   };
    #   sops.secrets."cache_li7g_com_key" = {
    #     predefined.enable = true;
    #     group = "hydra";
    #     mode = "440";
    #   };
    # }

    {
      # email notifications
      services.hydra.extraConfig = ''
        email_notification = 1
      '';
      # only the services that actually send mail: build notifications (notify),
      # evaluation errors (evaluator) and web ui password resets (server)
      systemd.services =
        lib.genAttrs
          [
            "hydra-evaluator"
            "hydra-notify"
            "hydra-server"
          ]
          (_: {
            serviceConfig.EnvironmentFile = config.sops.templates."hydra-email".path;
          });
      sops.templates."hydra-email".content = ''
        EMAIL_SENDER_TRANSPORT=SMTP
        EMAIL_SENDER_TRANSPORT_sasl_username=hydra@li7g.com
        EMAIL_SENDER_TRANSPORT_sasl_password=${config.sops.placeholder."mail_password"}
        EMAIL_SENDER_TRANSPORT_host=smtp.li7g.com
        EMAIL_SENDER_TRANSPORT_port=${toString config.ports.smtp-starttls}
        EMAIL_SENDER_TRANSPORT_ssl=starttls
      '';
      sops.secrets."mail_password" = {
        terraformOutput.enable = true;
        restartUnits = [
          "hydra-evaluator.service"
          "hydra-notify.service"
          "hydra-server.service"
        ];
      };
    }

    # decrease cpu weight
    {
      systemd.slices.system-hydra = {
        sliceConfig = {
          CPUWeight = "idle";
        };
      };
    }

    # webhook
    {
      sops.templates."hydra-extra-config".content = ''
        <webhooks>
          <github>
            secret = ${config.sops.placeholder."hydra_webhook_github_secret"}
          </github>
        </webhooks>
      '';
      sops.secrets."hydra_webhook_github_secret" = {
        terraformOutput.enable = true;
        restartUnits = [ "hydra.service" ];
      };
    }
  ];
}
