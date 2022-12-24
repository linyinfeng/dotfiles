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
in
{
  imports =
    suites.server ++
    (with profiles; [
      programs.telegram-send
      services.acme
      services.notify-failure
    ]) ++ [
      "${modulesPath}/profiles/qemu-guest.nix"
      # ./minio
      # ./maddy
      # ./vaultwarden
      # ./matrix
      # ./backup
      # ./influxdb
      # ./grafana
      # ./loki
      # ./git
      # ./alertmanager
      # ./seafile
      # ./mastodon
      # ./commit-notifier
      # ./pastebin
    ];

  config = lib.mkMerge [
    {
      i18n.defaultLocale = "en_US.UTF-8";
      console.keyMap = "us";
      time.timeZone = "Asia/Shanghai";

      boot.loader = {
        # efi support of hetzner is in beta
        # no efi variables to touch
        efi.canTouchEfiVariables = false;
        grub = {
          enable = true;
          efiSupport = true;
          version = 2;
          device = "/dev/sda";
        };
      };
      boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "sd_mod" "sr_mod" ];

      boot.tmpOnTmpfs = true;
      services.fstrim.enable = true;
      environment.global-persistence.enable = true;
      environment.global-persistence.root = "/persist";

      environment.systemPackages = with pkgs; [
        tmux
      ];

      services.btrfs.autoScrub = {
        enable = true;
        fileSystems = [
          "/dev/disk/by-uuid/9f227a19-d570-449f-b4cb-0eecc5b2d227"
        ];
      };

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
          device = "/dev/disk/by-uuid/5C56-7693";
          fsType = "vfat";
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

        virtualHosts."hil0.*" = {
          default = true;
          forceSSL = true;
          useACMEHost = "main";
        };
      };
      networking.firewall.allowedTCPPorts = [ 80 443 ];
    }

    # acme
    {
      security.acme.certs."main" = {
        domain = "*.li7g.com";
        extraDomainNames = [
          "*.zt.li7g.com"
          "*.ts.li7g.com"
        ];
      };
    }

    # postgresql
    {
      services.postgresql.enable = true;
    }

    # networking
    {
      networking = lib.mkIf (!config.system.is-vm) {
        useNetworkd = true;
        interfaces.enp1s0.useDHCP = true;
      };
    }
  ];
}
