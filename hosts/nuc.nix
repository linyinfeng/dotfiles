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

  grafanaPort = 3001;
  hydraPort = 3002;
  servePort = 3003;
  influxdbPort = 3004;
  lokiPort = 3005;

in
{
  imports =
    suites.homeServer ++
    suites.virtualization ++
    suites.tpm ++
    suites.fw ++
    suites.monitoring ++
    suites.campus;

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

      services.thermald.enable = true;
      services.scheduled-reboot.enable = true;

      environment.global-persistence.enable = true;
      environment.global-persistence.root = "/persist";

      boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
      boot.kernelModules = [ "kvm-intel" ];
      fileSystems."/" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [ "defaults" "size=8G" "mode=755" ];
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
            locations."/grafana/" = {
              proxyPass = "http://127.0.0.1:${toString grafanaPort}/";
            };
            locations."/hydra/" = {
              proxyPass = "http://127.0.0.1:${toString hydraPort}/";
              extraConfig = ''
                proxy_set_header X-Request-Base /hydra;
              '';
            };
            locations."/store/" = {
              proxyPass = "http://127.0.0.1:${toString servePort}/";
            };
          };
          "cache.li7g.com" = {
            locations."/" = {
              proxyPass = "http://127.0.0.1:${toString servePort}";
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

    # grafana
    {
      services.grafana = {
        addr = "127.0.0.1";
        enable = true;
        port = grafanaPort;
        rootUrl = "/grafana";
        auth.anonymous.enable = true;
        extraOptions = {
          "SERVER_SERVE_FROM_SUB_PATH" = "true";
        };
      };
      environment.global-persistence.directories = [
        "/var/lib/grafana"
      ];
      system.activationScripts.fixGrafanaPermission = {
        deps = [ "users" ];
        text = ''
          dir="${config.environment.global-persistence.root}/var/lib/grafana"
          mkdir -p "$dir"
          chown grafana "$dir"
        '';
      };
    }

    # loki
    {
      services.loki = {
        enable = true;
        configuration = {
          auth_enabled = false;
          server.http_listen_port = lokiPort;

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
        lokiPort
      ];
    }

    # influxdb
    {
      services.influxdb2 = {
        enable = true;
        settings = {
          http-bind-address = ":${toString influxdbPort}";
        };
      };
      environment.systemPackages = with pkgs; [
        influxdb2
      ];
      environment.global-persistence.directories = [
        "/var/lib/influxdb"
      ];
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
        influxdbPort
      ];
    }

    # hydra
    {
      services.hydra = {
        enable = true;
        listenHost = "127.0.0.1";
        port = hydraPort;
        hydraURL = "/hydra";
        notificationSender = "hydra@li7g.com";
        useSubstitutes = true;
        buildMachinesFiles = [
          "/etc/nix/machines"
        ];
        extraEnv = lib.mkIf (config.networking.fw-proxy.enable) config.networking.fw-proxy.environment;
      };
      environment.global-persistence.directories = [
        "/var/lib/hydra"
        "/var/lib/postgresql"
      ];
      nix.allowedUsers = [ "hydra" "hydra-www" ];
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
      sops.secrets."yinfeng/id-ed25519" = { };
    }

    # store serving
    {
      services.nix-serve = {
        enable = true;
        bindAddress = "127.0.0.1";
        port = servePort;
        secretKeyFile = config.sops.secrets."cache-li7g-com/key".path;
      };
      sops.secrets."cache-li7g-com/key" = { };
      nix.allowedUsers = [ "nix-serve" ];
    }
  ];
}
