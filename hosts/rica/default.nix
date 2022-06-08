{ pkgs, config, suites, profiles, lib, modulesPath, ... }:
let

  btrfsSubvol = device: subvol: extraConfig: lib.mkMerge [
    {
      inherit device;
      fsType = "btrfs";
      options = [ "subvol=${subvol}" "compress=zstd" ];
    }
    extraConfig
  ];

  btrfsSubvolMain = btrfsSubvol "/dev/disk/by-uuid/9f227a19-d570-449f-b4cb-0eecc5b2d227";

  cfg = config.hosts.rica;
in
{
  imports =
    suites.server ++
    (with profiles; [
      programs.telegram-send
      services.acme
      services.notify-failure
      services.restic
    ]) ++ [
      ./options.nix
      ./minio
      ./maddy
      ./vaultwarden
      ./matrix
      ./backup
      ./influxdb
      ./grafana
      ./loki
    ];

  config = lib.mkMerge [
    {
      i18n.defaultLocale = "en_US.UTF-8";
      console.keyMap = "us";
      time.timeZone = "Asia/Shanghai";

      boot.loader.grub = {
        enable = true;
        version = 2;
        device = "/dev/xvda";
      };
      boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "sr_mod" "xen_blkfront" ];

      boot.tmpOnTmpfs = true;
      services.fstrim.enable = true;
      environment.global-persistence.enable = true;
      environment.global-persistence.root = "/persist";

      environment.systemPackages = with pkgs; [
        tmux
      ];

      fileSystems."/" =
        {
          device = "tmpfs";
          fsType = "tmpfs";
          options = [ "defaults" "size=2G" "mode=755" ];
        };
      fileSystems."/persist" = btrfsSubvolMain "@persist" { neededForBoot = true; };
      fileSystems."/var/log" = btrfsSubvolMain "@var-log" { neededForBoot = true; };
      fileSystems."/nix" = btrfsSubvolMain "@nix" { neededForBoot = true; };
      fileSystems."/swap" = btrfsSubvolMain "@swap" { };
      fileSystems."/boot" =
        {
          device = "/dev/disk/by-uuid/4a186796-5865-4b47-985c-9354adec09a4";
          fsType = "ext4";
        };
      swapDevices =
        [{
          device = "/swap/swapfile";
        }];
    }

    # nginx
    {
      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        recommendedOptimisation = true;
        recommendedGzipSettings = true;

        virtualHosts = {
          "rica.li7g.com" = {
            default = true;
            forceSSL = true;
            useACMEHost = "main";
            serverAliases = [
              "rica.ts.li7g.com"
            ];
          };
        };
      };
      users.users.nginx.extraGroups = [ config.users.groups.acme.name ];
      networking.firewall.allowedTCPPorts = [ 80 443 ];
    }

    # acme
    {
      security.acme.certs."main" = {
        dnsProvider = "cloudflare";
        credentialsFile = config.sops.templates.acme-credentials.path;
        domain = "rica.li7g.com";
        extraDomainNames = [
          "rica.ts.li7g.com"
        ];
      };
      sops.secrets."cloudflare-token".sopsFile = config.sops.secretsDir + /common.yaml;
      sops.templates.acme-credentials.content = ''
        CLOUDFLARE_DNS_API_TOKEN=${config.sops.placeholder.cloudflare-token}
      '';
    }

    # commit-notifier
    {
      services.commit-notifier = {
        enable = true;
        cron = "0 */5 * * * *";
        tokenFile = config.sops.secrets."telegram-bot/commit-notifier".path;
      };
      sops.secrets."telegram-bot/commit-notifier".sopsFile = config.sops.secretsDir + /rica.yaml;

      services.notify-failure.services = [
        "commit-notifier"
      ];
    }

    # postgresql
    {
      services.postgresql.enable = true;
    }

    # pastebin
    {
      security.acme.certs."main".extraDomainNames = [
        "pb.li7g.com"
      ];
      services.nginx.virtualHosts."pb.li7g.com" = {
        forceSSL = true;
        useACMEHost = "main";
        locations."/".proxyPass = "http://127.0.0.1:${toString cfg.ports.pastebin}";
        extraConfig = ''
          client_max_body_size 25M;
        '';
      };
      systemd.services.pastebin = {
        script = ''
          export AWS_ACCESS_KEY_ID=$(cat "$CREDENTIALS_DIRECTORY/key-id")
          export AWS_SECRET_ACCESS_KEY=$(cat "$CREDENTIALS_DIRECTORY/access-key")
          ${pkgs.pastebin}/bin/pastebin \
            --endpoint-host minio.li7g.com \
            --bucket pastebin \
            --port "${toString cfg.ports.pastebin}"
        '';
        serviceConfig = {
          DynamicUser = true;
          LoadCredential = [
            "key-id:${config.sops.secrets."pastebin/key-id".path}"
            "access-key:${config.sops.secrets."pastebin/access-key".path}"
          ];
        };
        wantedBy = [ "multi-user.target" ];
      };
      sops.secrets."pastebin/key-id".sopsFile = config.sops.secretsDir + /rica.yaml;
      sops.secrets."pastebin/access-key".sopsFile = config.sops.secretsDir + /rica.yaml;

      services.notify-failure.services = [
        "pastebin"
      ];
    }

    (lib.mkIf (!config.system.is-vm) {
      networking.useNetworkd = true;
      environment.etc."systemd/network/50-enX0.network".source =
        config.sops.templates."enX0".path;
      sops.secrets."network/address".sopsFile = config.sops.secretsDir + /rica.yaml;
      sops.secrets."network/gateway".sopsFile = config.sops.secretsDir + /rica.yaml;
      sops.templates."enX0" = {
        content = ''
          [Match]
          Name=enX0

          [Network]
          Address=${config.sops.placeholder."network/address"}
          Gateway=${config.sops.placeholder."network/gateway"}
          DNS=8.8.8.8 8.8.4.4
        '';
        owner = "systemd-network";
      };
    })
  ];
}
