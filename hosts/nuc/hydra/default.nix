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

  services.nginx = {
    virtualHosts = {
      "nuc.li7g.com" = {
        locations."/hydra/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.ports.hydra}/";
          extraConfig = ''
            proxy_set_header X-Forwarded-Port 8443;
            proxy_set_header X-Request-Base /hydra;
          '';
        };
      };
    };
  };

  services.hydra = {
    enable = true;
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
  systemd.services.hydra-queue-runner.serviceConfig.SupplementaryGroups = [ config.users.groups.nix-access-tokens.name ];
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
  sops.secrets."nano/github-token" = { };
  sops.secrets."cache-li7g-com/key" = { };
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
  sops.secrets."nixbuild/id-ed25519".owner = "hydra-queue-runner";
}
