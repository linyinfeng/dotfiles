{ config, pkgs, lib, suites, profiles, ... }:

let

  btrfsSubvol = device: subvol: extraConfig: lib.mkMerge [
    {
      inherit device;
      fsType = "btrfs";
      options = [ "subvol=${subvol}" "compress=zstd" ];
    }
    extraConfig
  ];

  btrfsSubvolMain = btrfsSubvol "/dev/disk/by-uuid/8b982fe4-1521-4a4d-aafc-af22c3961093";
  btrfsSubvolMobile = btrfsSubvol "/dev/mapper/crypt-mobile";

  cfg = config.hosts.nuc;
in
{
  imports =
    suites.server ++
    suites.development ++
    suites.virtualization ++
    (with profiles; [
      nix.access-tokens
      nix.nixbuild
      security.tpm
      networking.network-manager
      networking.behind-fw
      networking.fw-proxy
      services.transmission
      services.samba
      services.vlmcsd
      services.teamspeak
      services.godns
      services.acme
      services.notify-failure
      programs.telegram-send
    ]) ++
    (with profiles.users; [
      yinfeng
      nianyi
    ]) ++ [
      ./options.nix
      ./influxdb
      ./grafana
      ./hydra
      ./vaultwarden
      ./backup
      ./matrix
    ];

  config = lib.mkMerge [
    {
      i18n.defaultLocale = "en_US.UTF-8";
      console.keyMap = "us";
      time.timeZone = "Asia/Shanghai";

      boot.loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot.enable = true;
      };
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
      hardware.enableRedistributableFirmware = true;
      services.fwupd.enable = true;

      services.thermald.enable = true;

      networking.campus-network = {
        enable = true;
        auto-login.enable = true;
      };

      environment.global-persistence.enable = true;
      environment.global-persistence.root = "/persist";

      boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "vmd" "ahci" "nvme" "usbhid" "uas" "sd_mod" ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.initrd.luks.forceLuksSupportInInitrd = true;
      boot.initrd.kernelModules = [ "tpm" "tpm_tis" "tpm_crb" ];
      boot.initrd.preLVMCommands = ''
        waitDevice /dev/disk/by-uuid/b456f27c-b0a1-4b1e-8f2b-91f1826ae51c
        ${pkgs.clevis}/bin/clevis luks unlock -d /dev/disk/by-uuid/b456f27c-b0a1-4b1e-8f2b-91f1826ae51c -n crypt-mobile
      '';
      fileSystems."/" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [ "defaults" "size=2G" "mode=755" ];
      };
      boot = {
        tmpOnTmpfs = true;
        tmpOnTmpfsSize = "50%";
      };
      fileSystems."/nix" = btrfsSubvolMain "@nix" { neededForBoot = true; };
      fileSystems."/persist" = btrfsSubvolMain "@persist" { neededForBoot = true; };
      fileSystems."/var/log" = btrfsSubvolMain "@var-log" { neededForBoot = true; };
      fileSystems."/swap" = btrfsSubvolMain "@swap" { };
      fileSystems."/boot" =
        {
          device = "/dev/disk/by-uuid/C9A4-3DE6";
          fsType = "vfat";
        };
      swapDevices = [{
        device = "/swap/swapfile";
      }];
      fileSystems."/var/lib/transmission" = btrfsSubvolMobile "@bittorrent" { };
      fileSystems."/media/data" = btrfsSubvolMobile "@data" { };
    }

    # godns
    {
      services.godns = {
        ipv4.settings = {
          domains = [{
            domain_name = "li7g.com";
            sub_domains = [ "nuc" ];
          }];
          ip_type = "IPv4";
          ip_url = "https://myip.biturl.top";
        };
        ipv6.settings = {
          domains = [{
            domain_name = "li7g.com";
            sub_domains = [ "nuc" ];
          }];
          ip_type = "IPv6";
          ip_interface = "enp88s0";
        };
      };
    }

    # acme
    {
      security.acme.certs."main" = {
        dnsProvider = "cloudflare";
        credentialsFile = config.sops.templates.acme-credentials.path;
        domain = "nuc.li7g.com";
        extraDomainNames = [
          "home.li7g.com"
          "nuc.ts.li7g.com"
          "vault.li7g.com"
          "vault.ts.li7g.com"
          "matrix.li7g.com"
          "matrix.ts.li7g.com"
        ];
      };
      sops.secrets."cloudflare-token".sopsFile = config.sops.secretsDir + /common.yaml;
      sops.templates.acme-credentials.content = ''
        CLOUDFLARE_DNS_API_TOKEN=${config.sops.placeholder.cloudflare-token}
      '';
      users.users.nginx.extraGroups = [ config.users.groups.acme.name ];
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
          "nuc.li7g.com" = {
            forceSSL = true;
            useACMEHost = "main";
            listen = config.hosts.nuc.listens;
            serverAliases = [
              "home.li7g.com"
              "nuc.ts.li7g.com"
              "nuc-proxy.li7g.com"
            ];
            locations."/" = {
              root = ./www;
            };
          };
        };
      };
      networking.firewall.allowedTCPPorts = [
        80
        443
        8443
      ];
    }

    # postgresql
    {
      services.postgresql.enable = true;
    }

    # loki
    {
      services.loki = {
        enable = true;
        configuration = {
          auth_enabled = false;
          server.http_listen_port = cfg.ports.loki;

          common = {
            path_prefix = config.services.loki.dataDir;
            replication_factor = 1;
            ring = {
              instance_addr = "127.0.0.1";
              kvstore.store = "inmemory";
            };
          };

          compactor = {
            retention_enabled = true;
          };
          limits_config = {
            retention_period = "336h"; # 14 days
          };

          schema_config.configs = [
            {
              from = "2020-10-24";
              store = "boltdb-shipper";
              object_store = "filesystem";
              schema = "v11";
              index = {
                prefix = "index_";
                period = "24h";
              };
            }
          ];
        };
      };
    }

    # store serving
    {
      services.nginx = {
        virtualHosts = {
          "nuc.li7g.com" = {
            locations."/store/" = {
              proxyPass = "http://127.0.0.1:${toString cfg.ports.nixServe}/";
              extraConfig = ''
                proxy_max_temp_file_size 0;
              '';
            };
          };
        };
      };
      services.nix-serve = {
        enable = true;
        bindAddress = "0.0.0.0";
        port = cfg.ports.nixServe;
        secretKeyFile = config.sops.secrets."cache-li7g-com/key".path;
      };
      sops.secrets."cache-li7g-com/key".sopsFile = config.sops.secretsDir + /nuc.yaml;

      # TODO broken: cannot determine user's home directory
      systemd.services.nix-serve = {
        serviceConfig = {
          Group = lib.mkForce "hydra";
          RuntimeDirectory = "nix-serve";
        };
        environment.HOME = "$RUNTIME_DIRECTORY";
      };
    }

    # transmission
    # extra settings for suites.transmission
    {
      sops.secrets."transmission/credentials".sopsFile = config.sops.secretsDir + /nuc.yaml;
    }
  ];
}
