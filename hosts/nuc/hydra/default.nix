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

  services.hydra = {
    enable = true;
    listenHost = "127.0.0.1";
    port = cfg.ports.hydra;
    hydraURL = "https://nuc.li7g.com/hydra";
    notificationSender = "hydra@li7g.com";
    useSubstitutes = true;
    buildMachinesFiles = [
      "/etc/nix/machines"
    ];
    extraEnv = lib.mkIf (config.networking.fw-proxy.enable) config.networking.fw-proxy.environment;
    extraConfig = ''
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
  sops.templates."hydra-extra-config" = {
    group = "hydra";
    mode = "440";
    content = ''
      <github_authorization>
        linyinfeng = Bearer ${config.sops.placeholder."hydra/github-token"}
        littlenano = Bearer ${config.sops.placeholder."hydra/github-token"}
      </github_authorization>
    '';
  };
  sops.secrets."hydra/github-token" = { };
  environment.global-persistence.directories = [
    "/var/lib/hydra"
    "/var/lib/postgresql"
  ];
  nix.allowedUsers = [ "@hydra" ];
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
