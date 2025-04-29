{
  config,
  lib,
  pkgs,
  ...
}:
let
  hydraHook = pkgs.writeShellApplication {
    name = "hydra-hook";
    runtimeInputs = with pkgs; [
      jq
      systemd
      postgresql
      ripgrep
    ];
    text = ''
      time=$(date --iso-8601=seconds)
      mkdir -p "/tmp/hydra-events"
      dump_file=$(mktemp "/tmp/hydra-events/$time-XXXXXX.json")
      cp "$HYDRA_JSON" "$dump_file"

      hit=$(jq '
        .project == "dotfiles" and
        (.jobset == "main" or .jobset == "staging") and
        .buildStatus == 0 and
        .event == "buildFinished"
      ' "$HYDRA_JSON")
      echo "hit = $hit"

      if [ "$hit" = "true" ]; then
        job=$(jq --raw-output ".job" "$HYDRA_JSON")
        echo "job = $job"

        if [[ $job =~ ^nixos-([^/]*)\.(.*)$ && "$(jq --raw-output '.jobset' "$HYDRA_JSON")" == "main" ]]; then
          host="''${BASH_REMATCH[1]}"
          _system="''${BASH_REMATCH[2]}"

          build_id=$(jq '.build' "$HYDRA_JSON")
          flake_url=$(psql -t -U hydra -d hydra -c "
                SELECT flake FROM jobsetevals
                WHERE id = (SELECT eval FROM jobsetevalmembers
                            WHERE build = $build_id
                            LIMIT 1)
                ORDER BY id DESC
                LIMIT 1
            ")
          commit=$(echo "$flake_url" | rg --only-matching '/(\w{40})(\?.*)?$' --replace '$1')

          mkdir -p "/tmp/dotfiles-channel-update"
          update_file="/tmp/dotfiles-channel-update/$(basename "$dump_file")"
          jq \
            --arg host "$host" \
            --arg commit "$commit" \
            '{
            host: $host,
            commit: $commit,
            outs: .products | map(.path),
          }' "$HYDRA_JSON" >"$update_file"

          echo "channel update: $update_file"
          cat "$update_file"
          systemctl start "dotfiles-channel-update@$(systemd-escape "$update_file")" --no-block

        else
          echo "job is not a nixos toplevel, or jobset is not main"

          echo "copy out: $out"
          jq --raw-output '.products[].path' "$HYDRA_JSON" | (
            while read -r out; do
              systemctl start "copy-cache-li7g-com@$(systemd-escape "$out").service" --no-block
            done
          )
        fi
      fi
    '';
  };
in
{
  imports = [
    ./_dotfiles-channel-update.nix
    ./_cache.nix
  ];

  config = lib.mkMerge [
    {
      services.nginx.virtualHosts."hydra.*" = {
        forceSSL = true;
        inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
        serverAliases = [ "hydra-proxy.*" ];
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.ports.hydra}";
        };
      };

      services.hydra = {
        enable = true;
        package = pkgs.hydra;
        listenHost = "127.0.0.1";
        port = config.ports.hydra;
        hydraURL = "https://hydra.li7g.com";
        notificationSender = "hydra@li7g.com";
        useSubstitutes = true;
        extraEnv = lib.mkIf config.networking.fw-proxy.enable config.networking.fw-proxy.environment;
        extraConfig = ''
          Include "${config.sops.templates."hydra-extra-config".path}"

          max_concurrent_evals = 1

          <githubstatus>
            jobs = .*
            excludeBuildFromContext = 1
          </githubstatus>
          <runcommand>
            command = "${lib.getExe hydraHook}"
          </runcommand>
        '';
      };
      services.hydra.buildMachinesFiles = [ "/etc/nix-build-machines/hydra-builder/machines" ];
      # allow evaluator and queue-runner to access nix-access-tokens
      systemd.services.hydra-evaluator.serviceConfig.SupplementaryGroups = [
        config.users.groups.nix-access-tokens.name
      ];
      systemd.services.hydra-queue-runner.serviceConfig.SupplementaryGroups = [
        config.users.groups.nix-access-tokens.name
        config.users.groups.hydra-builder-client.name
      ];
      sops.templates."hydra-extra-config" = {
        group = "hydra";
        mode = "440";
        content = ''
          <github_authorization>
            linyinfeng = Bearer ${config.sops.placeholder."nano/github-token"}
            littlenano = Bearer ${config.sops.placeholder."nano/github-token"}
          </github_authorization>
        '';
      };
      nix.settings.secret-key-files = [ "${config.sops.secrets."cache-li7g-com/key".path}" ];
      nix.settings.allowed-uris = [
        "github:"
        "gitlab:"
        "https://github.com/"
        "https://gitlab.com/"
        "https://git.sr.ht/"
        "git+https://github.com/"
        "git+https://gitlab.freedesktop.org/"
      ];
      sops.secrets."nano/github-token" = {
        sopsFile = config.sops-file.get "common.yaml";
        restartUnits = [ "hydra.service" ];
      };
      sops.secrets."cache-li7g-com/key" = {
        sopsFile = config.sops-file.host;
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
    #         config.sops.secrets."cache-li7g-com/key".path
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
    #   sops.secrets."cache-li7g-com/key" = {
    #     sopsFile = config.sops-file.host;
    #     group = "hydra";
    #     mode = "440";
    #   };
    # }

    {
      # email notifications
      services.hydra.extraConfig = ''
        email_notification = 1
      '';
      systemd.services.hydra-notify.serviceConfig.EnvironmentFile =
        config.sops.templates."hydra-email".path;
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
        restartUnits = [ "hydra-notify.service" ];
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
  ];
}
