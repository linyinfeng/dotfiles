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
    suites.user-yinfeng ++
    suites.user-nianyi ++ [
      ./influxdb
      ./grafana
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
      services.scheduled-reboot.enable = true;

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

    # hydra
    {
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

        package = pkgs.hydra-unstable.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            ./patches/hydra-non-local.patch
          ];
        });

        extraConfig = ''
          Include "${config.sops.templates."hydra-extra-config".path}"
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
          <githubstatus>
            jobs = .*
            excludeBuildFromContext = 1
          </githubstatus>
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
        # disabled
        (lib.mkIf false {
          hostName = "eu.nixbuild.net";
          systems = [
            "x86_64-linux"
            "i686-linux"
            "aarch64-linux"
          ];
          supportedFeatures = [ "benchmark" "big-parallel" ];
          mandatoryFeatures = [ "non-local" ];
          maxJobs = 100;
          speedFactor = 2;
        })
      ];
      sops.secrets."nixbuild/id-ed25519".owner = "hydra-queue-runner";
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
