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
      programs.tg-send
      services.nginx
      services.acme
      services.notify-failure
    ]) ++ [
      ./minio
      ./maddy
      ./vaultwarden
      ./backup
      ./git
      ./seafile
      ./mastodon
      ./commit-notifier
      ./pastebin
      ./alertmanager
      ./influxdb
      ./loki
      ./grafana
      ./static-file-hosting
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
          device = "/dev/disk/by-uuid/4a186796-5865-4b47-985c-9354adec09a4";
          fsType = "ext4";
        };
      swapDevices =
        [{
          device = "/swap/swapfile";
        }];
    }

    # postgresql
    {
      services.postgresql.enable = true;
    }

    (lib.mkIf (!config.system.is-vm) {
      networking.useNetworkd = true;
      environment.etc."systemd/network/50-enX0.network".source =
        config.sops.templates."enX0".path;
      sops.secrets."network/address" = {
        sopsFile = config.sops-file.get "hosts/rica-terraform.yaml";
        restartUnits = [ "systemd-networkd.service" ];
      };
      sops.secrets."network/subnet" = {
        sopsFile = config.sops-file.host;
        restartUnits = [ "systemd-networkd.service" ];
      };
      sops.secrets."network/gateway" = {
        sopsFile = config.sops-file.host;
        restartUnits = [ "systemd-networkd.service" ];
      };
      sops.templates."enX0" = {
        content = ''
          [Match]
          Name=enX0

          [Network]
          Address=${config.sops.placeholder."network/address"}/${config.sops.placeholder."network/subnet"}
          Gateway=${config.sops.placeholder."network/gateway"}
          DNS=8.8.8.8 8.8.4.4
        '';
        owner = "systemd-network";
      };
    })
  ];
}
