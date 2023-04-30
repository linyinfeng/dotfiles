{
  pkgs,
  config,
  suites,
  profiles,
  lib,
  modulesPath,
  ...
}: {
  imports =
    suites.server
    ++ (with profiles; [
      programs.tg-send
      services.nginx
      services.acme
      services.notify-failure
      services.postgresql
    ])
    ++ [
      "${modulesPath}/profiles/qemu-guest.nix"
    ];

  config = lib.mkMerge [
    {
      boot.loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot.enable = true;
      };
      boot.initrd.availableKernelModules = ["xhci_pci" "virtio_pci" "usbhid" "sr_mod"];

      boot.tmp.useTmpfs = true;
      services.fstrim.enable = true;
      environment.global-persistence.enable = true;
      environment.global-persistence.root = "/persist";

      services.btrfs.autoScrub = {
        enable = true;
        fileSystems = [
          config.fileSystems."/persist".device
        ];
      };

      disko.devices = {
        nodev."/" = {
          fsType = "tmpfs";
          mountOptions = ["defaults" "size=2G" "mode=755"];
        };
        disk.main = {
          type = "disk";
          device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_31303657";
          content = {
            type = "table";
            format = "gpt";
            partitions = [
              {
                name = "efi";
                start = "1MiB"; # 2048 sectors (512 bytes per sector)
                end = "1025MiB"; # total size 1024 MiB
                fs-type = "fat32";
                bootable = true;
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                };
              }
              {
                name = "root";
                start = "1025MiB";
                end = "-4GiB";
                fs-type = "btrfs";
                content = {
                  type = "btrfs";
                  subvolumes = {
                    "@persist" = {
                      mountpoint = "/persist";
                      mountOptions = ["compress=zstd"];
                    };
                    "@var-log" = {
                      mountpoint = "/var/log";
                      mountOptions = ["compress=zstd"];
                    };
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = ["compress=zstd"];
                    };
                  };
                };
              }
              {
                name = "swap";
                start = "-4GiB";
                end = "100%";
                fs-type = "linux-swap";
                content = {
                  type = "swap";
                };
              }
            ];
          };
        };
      };
      fileSystems."/persist".neededForBoot = true;
      fileSystems."/var/log".neededForBoot = true;
    }

    # networking
    (lib.mkIf (!config.system.is-vm) {
      networking.useNetworkd = true;
      environment.etc."systemd/network/45-enp1s0.network".source =
        config.sops.templates."enp1s0".path;
      sops.templates."enp1s0" = {
        content = ''
          [Match]
          Name=enp1s0

          [Network]
          DHCP=ipv4

          # manual ipv6 configuration
          Address=${config.sops.placeholder."fsn0_ipv6_address"}/${config.sops.placeholder."fsn0_ipv6_prefix_length"}
          Gateway=fe80::1
          DNS=2a01:4ff:ff00::add:1
          DNS=2a01:4ff:ff00::add:2
        '';
        owner = "systemd-network";
      };
      sops.secrets."fsn0_ipv6_address" = {
        sopsFile = config.sops-file.terraform;
        restartUnits = ["systemd-networkd.service"];
      };
      sops.secrets."fsn0_ipv6_prefix_length" = {
        sopsFile = config.sops-file.terraform;
        restartUnits = ["systemd-networkd.service"];
      };
    })
  ];
}
