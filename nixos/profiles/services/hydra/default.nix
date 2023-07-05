{
  config,
  lib,
  pkgs,
  profiles,
  ...
}: let
  cfg = config.hosts.nuc;
  hydra-hook = pkgs.substituteAll {
    src = ./hook.sh;
    isExecutable = true;
    inherit (pkgs.stdenvNoCC) shell;
    inherit (pkgs) jq systemd postgresql;
  };
in {
  imports = [
    ./_dotfiles-channel-update.nix
    ./_cache.nix
  ];

  config = lib.mkMerge [
    {
      services.nginx.virtualHosts."hydra.*" = {
        forceSSL = true;
        useACMEHost = "main";
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.ports.hydra}";
        };
      };

      services.hydra = {
        enable = true;
        package = pkgs.hydra-master;
        listenHost = "127.0.0.1";
        port = config.ports.hydra;
        hydraURL = "https://hydra.li7g.com";
        notificationSender = "hydra@li7g.com";
        useSubstitutes = true;
        extraEnv = lib.mkIf (config.networking.fw-proxy.enable) config.networking.fw-proxy.environment;
        extraConfig = ''
          # use secret-key-files option in nix.conf instead
          # store-uri = file:///nix/store?secret-key=${config.sops.secrets."cache-li7g-com/key".path}

          Include "${config.sops.templates."hydra-extra-config".path}"

          <githubstatus>
            jobs = .*
            excludeBuildFromContext = 1
          </githubstatus>
          <runcommand>
            command = "${hydra-hook}"
          </runcommand>
        '';
      };
      # allow evaluator and queue-runner to access nix-access-tokens
      systemd.services.hydra-evaluator.serviceConfig.SupplementaryGroups = [config.users.groups.nix-access-tokens.name];
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
      nix.settings.secret-key-files = [
        "${config.sops.secrets."cache-li7g-com/key".path}"
      ];
      nix.settings.allowed-uris = [
        "https://github.com/" # for nix-index-database
        "https://gitlab.com/" # for home-manager nmd source
        "https://git.sr.ht/" # for home-manager nmd source
      ];
      sops.secrets."nano/github-token" = {
        sopsFile = config.sops-file.get "common.yaml";
        restartUnits = ["hydra.service"];
      };
      sops.secrets."cache-li7g-com/key" = {
        sopsFile = config.sops-file.host;
        restartUnits = ["nix-daemon.service"];
      };
      nix.settings.trusted-users = ["@hydra"];
    }

    {
      # email notifications
      services.hydra.extraConfig = ''
        email_notification = 1
      '';
      systemd.services.hydra-notify.serviceConfig.EnvironmentFile = config.sops.templates."hydra-email".path;
      sops.templates."hydra-email".content = ''
        EMAIL_SENDER_TRANSPORT=SMTP
        EMAIL_SENDER_TRANSPORT_sasl_username=hydra@li7g.com
        EMAIL_SENDER_TRANSPORT_sasl_password=${config.sops.placeholder."mail_password"}
        EMAIL_SENDER_TRANSPORT_host=smtp.ts.li7g.com
        EMAIL_SENDER_TRANSPORT_port=${toString config.ports.smtp-starttls}
        EMAIL_SENDER_TRANSPORT_ssl=starttls
      '';
      sops.secrets."mail_password" = {
        sopsFile = config.sops-file.get "terraform/common.yaml";
        restartUnits = ["hydra-notify.service"];
      };
    }
  ];
}
