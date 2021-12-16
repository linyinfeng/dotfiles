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

in
{
  imports =
    suites.homeServer ++
    suites.virtualization ++
    suites.tpm ++
    suites.fw ++
    suites.nixbuild ++
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

      services.godns = {
        ipv4.settings = {
          domains = [{
            domain_name = "li7g.com";
            sub_domains = [ "nuc" ];
          }];
          ip_type = "IPv4";
          ip_interface = "enp88s0";
          # TODO if public ip working change to `ip_url`
          # ip_url = "https://myip.biturl.top";
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
          "nuc.li7g.com" = {
            default = true;
            locations."/" = {
              proxyPass = "http://localhost:${toString grafanaPort}";
            };
          };
          "hydra.li7g.com" = {
            locations."/" = {
              proxyPass = "http://localhost:${toString hydraPort}";
            };
          };
        };
      };
      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
    }

    # monitoring
    {
      services.grafana = {
        enable = true;
        port = grafanaPort;
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

    # hydra
    {
      services.hydra = {
        enable = true;
        listenHost = "localhost";
        port = hydraPort;
        hydraURL = "hydra.li7g.com";
        notificationSender = "hydra@li7g.com";
        useSubstitutes = true;
        buildMachinesFiles = [
          "/etc/nix/machines"
          "/etc/nixbuild/machines"
        ];
      };
      systemd.services.hydra-evaluator = {
        environment = lib.mkIf (config.networking.fw-proxy.enable) config.networking.fw-proxy.environment;
      };
      environment.global-persistence.directories = [
        "/var/lib/hydra"
        "/var/lib/postgresql"
      ];
      nix.trustedUsers = [ "hydra" ];
      nix.distributedBuilds = true;
      users.users.hydra = {
        extraGroups = [
          config.users.groups.nixbuild.name
        ];
      };
      sops.secrets."nixbuild/id-ed25519".owner = config.users.users.hydra.name;
      nix.buildMachines = [
        {
          hostName = "localhost";
          systems = [
            "x86_64-linux"
            "i686-linux"
          ];
          supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ];
          maxJobs = 4;
          speedFactor = 1;
        }
      ];
      sops.secrets."yinfeng/id-ed25519" = { };
    }
  ];
}
