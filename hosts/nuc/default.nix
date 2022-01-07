{ config, pkgs, lib, suites, ... }:

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

  cfg = config.hosts.nuc;
in
{
  imports =
    suites.server ++
    suites.networkManager ++
    suites.godns ++
    suites.virtualization ++
    suites.tpm ++
    suites.fw ++
    suites.monitoring ++
    suites.nixbuild ++
    suites.auto-upgrade ++
    suites.user-yinfeng ++
    suites.user-nianyi ++ [
      ./influxdb
      ./grafana
      ./hydra
    ];

  options.hosts.nuc = {
    ports = {
      grafana = lib.mkOption {
        type = lib.types.port;
        default = 3001;
      };
      hydra = lib.mkOption {
        type = lib.types.port;
        default = 3002;
      };
      nixServe = lib.mkOption {
        type = lib.types.port;
        default = 3003;
      };
      influxdb = lib.mkOption {
        type = lib.types.port;
        default = 3004;
      };
      loki = lib.mkOption {
        type = lib.types.port;
        default = 3005;
      };
    };
  };

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

      boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
      boot.kernelModules = [ "kvm-intel" ];
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
    }

    # nginx
    {
      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        virtualHosts = {
          "nuc.ts.li7g.com" = {
            default = true;
            locations."/" = {
              root = ./www;
            };
            locations."/grafana/" = {
              proxyPass = "http://127.0.0.1:${toString cfg.ports.grafana}/";
            };
            locations."/hydra/" = {
              proxyPass = "http://127.0.0.1:${toString cfg.ports.hydra}/";
              extraConfig = ''
                proxy_set_header X-Request-Base /hydra;
              '';
            };
            locations."/store/" = {
              proxyPass = "http://127.0.0.1:${toString cfg.ports.nixServe}/";
            };
          };
          "cache.li7g.com" = {
            locations."/" = {
              proxyPass = "http://127.0.0.1:${toString cfg.ports.nixServe}";
            };
          };
        };
      };
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
        80
      ];
      networking.firewall.allowedTCPPorts = [
        443
      ];
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
      environment.global-persistence.directories = [
        config.services.loki.dataDir
      ];
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
        cfg.ports.loki
      ];
    }

    # store serving
    {
      services.nix-serve = {
        enable = true;
        bindAddress = "127.0.0.1";
        port = cfg.ports.nixServe;
        secretKeyFile = config.sops.secrets."cache-li7g-com/key".path;
      };
      sops.secrets."cache-li7g-com/key" = { };
      nix.allowedUsers = [ "nix-serve" ];
    }

    # geth
    {
      services.geth.light = {
        enable = true;
        syncmode = "light";
        http.enable = true;
      };
      environment.global-persistence.directories = [
        "/var/lib/private/goethereum"
      ];
    }
  ];
}
