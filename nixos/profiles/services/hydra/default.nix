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
      getFlakeCommit
      channelUpdate
    ];
    text = ''
      echo "--- begin event ---"
      cat "$HYDRA_JSON" | jq
      echo "--- end event ---"

      time=$(date --iso-8601=seconds)
      mkdir -p "/tmp/hydra-events"
      dump_file=$(mktemp "/tmp/hydra-events/$time-XXXXXX.json")
      cp "$HYDRA_JSON" "$dump_file"
      echo "event saved in: $dump_file"

      if [ "$(jq '.event == "buildFinished" and .buildStatus == 0' "$HYDRA_JSON")"  != "true" ]; then
        echo "not a successful buildFinished event, exit."
        exit 0
      fi

      echo "copying outputs to cache..."
      jq --raw-output '.outputs[].path' "$HYDRA_JSON" | while read -r out; do
        echo "copying to cache: $out..."
        systemctl start "copy-cache-li7g-com@$(systemd-escape "$out").service"
        echo "done."
      done

      if [ "$(jq --from-file "${dotfilesChannelJobFilter}" "$HYDRA_JSON")" = "true" ]; then
        echo "dotfiles channel job detected, update channel..."
        host="$(jq --raw-output '.job | capture("^nixos-(?<host>[^/]*)\\.(.*)$").host' "$HYDRA_JSON")"
        branch="nixos-tested-$host"
        commit="$(get-flake-commit)"
        channel-update "linyinfeng" "dotfiles" "$branch" "$commit"
      fi
    '';
  };
  dotfilesChannelJobFilter = pkgs.writeTextFile {
    name = "nixos-job-filter.jq";
    text = ''
      .project == "dotfiles" and
      .jobset == "main" and
      (.job | test("^nixos-([^/]*)\\.(.*)$"))
    '';
  };
  # currently github only
  channelUpdate = pkgs.writeShellApplication {
    name = "channel-update";
    runtimeInputs = with pkgs; [
      jq
      git
      util-linux
    ];
    text = ''
      owner="$1"
      repo="$2"
      branch="$3"
      commit="$4"
      token=$(cat "$CREDENTIALS_DIRECTORY/github-token")

      echo "updating $owner/$repo/$branch to $commit..."

      cd /var/tmp
      mkdir --parents "hydra-channel-update/$owner/$repo"
      cd "hydra-channel-update/$owner/$repo"

      (
        echo "waiting for repository lock..."
        flock 200
        echo "enter critical section"

        if [ ! -d "repo.git" ]; then
          git clone "https://github.com/$owner/$repo.git" --filter=tree:0 --bare repo.git
        fi

        function repo-git {
          git -C repo.git "$@"
        }

        repo-git remote set-url origin "https://-:$token@github.com/$owner/$repo.git"
        repo-git fetch --all
        if repo-git merge-base --is-ancestor "$commit" "$branch"; then
          echo "commit $commit is already in branch $branch, skip."
          exit 0
        fi
        repo-git push origin "$commit:$branch"

        echo "leave critical section"
      ) 200>lock
    '';
  };
  getFlakeCommit = pkgs.writeShellApplication {
    name = "get-flake-commit";
    runtimeInputs = with pkgs; [
      jq
      postgresql
      ripgrep
    ];
    text = ''
      build_id=$(jq '.build' "$HYDRA_JSON")
      flake_url=$(psql -t -U hydra -d hydra -c "
            SELECT flake FROM jobsetevals
            WHERE id = (SELECT eval FROM jobsetevalmembers
                        WHERE build = $build_id
                        LIMIT 1)
            ORDER BY id DESC
            LIMIT 1
        ")
      echo "$flake_url" | rg --only-matching '/(\w{40})(\?.*)?$' --replace '$1'
    '';
  };
in
{
  imports = [
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

    # run command
    {
      services.hydra.extraConfig = lib.mkAfter ''
        <runcommand>
          command = "${lib.getExe hydraHook}"
        </runcommand>
      '';
      systemd.services.hydra-notify.serviceConfig.LoadCredential = [
        "github-token:${config.sops.secrets."github_token_nano".path}"
      ];
      sops.secrets."github_token_nano".restartUnits = [ "hydra-notify.service" ];
      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.systemd1.manage-units" &&
              RegExp('copy-cache-li7g-com@.+\.service').test(action.lookup("unit")) === true &&
              subject.isInGroup("hydra")) {
            return polkit.Result.YES;
          }
        });
      '';
    }

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
