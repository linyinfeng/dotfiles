{ config, lib, pkgs, ... }:

let
  cfg = config.hosts.nuc;
  hydra-hook = pkgs.substituteAll {
    src = ./hook.sh;
    isExecutable = true;
    inherit (pkgs.stdenvNoCC) shell;
    inherit (pkgs) jq systemd postgresql;
  };
in
{
  imports = [
    ./dotfiles-channel-update.nix
  ];

  config = lib.mkMerge [
    {
      services.nginx = {
        virtualHosts = {
          "nuc.li7g.com" = {
            locations."/hydra/" = {
              proxyPass = "http://127.0.0.1:${toString cfg.ports.hydra}/";
              extraConfig = ''
                proxy_set_header X-Forwarded-Port $server_port;
                proxy_set_header X-Request-Base /hydra;
              '';
            };
          };
        };
      };

      services.hydra = {
        enable = true;
        package = pkgs.hydra-master;
        listenHost = "127.0.0.1";
        port = cfg.ports.hydra;
        hydraURL = "https://nuc.li7g.com:8443/hydra";
        notificationSender = "hydra@li7g.com";
        useSubstitutes = true;
        buildMachinesFiles = [
          "/etc/nix/machines"
        ];
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
      systemd.services.hydra-evaluator.serviceConfig.SupplementaryGroups = [ config.users.groups.nix-access-tokens.name ];
      systemd.services.hydra-queue-runner.serviceConfig.SupplementaryGroups = [
        config.users.groups.nix-access-tokens.name
        config.users.groups.nixbuild.name
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
      # limit cpu quota of nix builds
      systemd.services.nix-daemon.serviceConfig.CPUQuota = "400%";
      sops.secrets."nano/github-token".sopsFile = config.sops.secretsDir + /common.yaml;
      sops.secrets."cache-li7g-com/key".sopsFile = config.sops.secretsDir + /nuc.yaml;
      nix.settings.allowed-users = [ "@hydra" ];
      nix.distributedBuilds = true;
      nix.buildMachines = [
        {
          hostName = "localhost";
          systems = [
            "x86_64-linux"
            "i686-linux"
            "aarch64-linux"
          ];
          supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ];
          maxJobs = 4;
          speedFactor = 1;
        }
      ];
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
        EMAIL_SENDER_TRANSPORT_sasl_password=${config.sops.placeholder."mail/password"}
        EMAIL_SENDER_TRANSPORT_host=smtp.ts.li7g.com
        EMAIL_SENDER_TRANSPORT_port=465
        EMAIL_SENDER_TRANSPORT_ssl=1
      '';
      sops.secrets."mail/password".sopsFile = config.sops.secretsDir + /common.yaml;
    }
  ];
}
