{
  config,
  suites,
  profiles,
  lib,
  modulesPath,
  ...
}:
{
  imports =
    suites.overseaServer
    ++ (with profiles; [
      programs.tg-send
      services.nginx
      services.acme
      services.notify-failure
      services.postgresql
      services.influxdb
      services.dn42-site
      services.bird-lg
      services.keycloak
      services.matrix
      # my account is banned by openai
      # services.matrix-chatgpt-bot
      services.mastodon
      services.maddy
      services.well-known
      nix.access-tokens
      nix.hydra-builder-server
    ])
    ++ [ "${modulesPath}/profiles/qemu-guest.nix" ];

  config = lib.mkMerge [
    {
      boot.loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot.enable = true;
      };
      boot.initrd.availableKernelModules = [
        "xhci_pci"
        "virtio_pci"
        "usbhid"
        "sr_mod"
      ];

      boot.tmp.cleanOnBoot = true;
      services.fstrim.enable = true;
      environment.global-persistence.enable = true;
      environment.global-persistence.root = "/persist";

      services.btrfs.autoScrub = {
        enable = true;
        fileSystems = [ config.fileSystems."/persist".device ];
      };

      disko.devices = {
        nodev."/" = {
          fsType = "tmpfs";
          mountOptions = [
            "defaults"
            "size=2G"
            "mode=755"
          ];
        };
        disk.main =
          let
            swapSize = "4GiB";
          in
          {
            type = "disk";
            device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_31303657";
            content = {
              type = "gpt";
              partitions = {
                ESP = {
                  start = "1MiB"; # 2048 sectors (512 bytes per sector)
                  end = "1025MiB"; # total size 1024 MiB
                  type = "EF00";
                  content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/boot";
                    mountOptions = [
                      "dmask=077"
                      "fmask=177"
                    ];
                  };
                };
                root = {
                  start = "1025MiB";
                  end = "-${swapSize}";
                  content = {
                    type = "btrfs";
                    subvolumes =
                      let
                        mountOptions = [ "compress=zstd" ];
                      in
                      {
                        "@persist" = {
                          mountpoint = "/persist";
                          inherit mountOptions;
                        };
                        "@var-log" = {
                          mountpoint = "/var/log";
                          inherit mountOptions;
                        };
                        "@nix" = {
                          mountpoint = "/nix";
                          inherit mountOptions;
                        };
                        "@tmp" = {
                          mountpoint = "/tmp";
                          inherit mountOptions;
                        };
                        "@swap" = {
                          mountpoint = "/swap";
                          inherit mountOptions;
                          swap.swapfile.size = "8G";
                        };
                      };
                  };
                };
              };
            };
          };
      };
      fileSystems."/persist".neededForBoot = true;
      fileSystems."/var/log".neededForBoot = true;
      services.zswap.enable = true;

      system.nproc = 8;
    }

    # networking
    (lib.mkIf (!config.system.is-vm) {
      environment.etc."systemd/network/45-enp1s0.network".source = config.sops.templates."enp1s0".path;
      sops.templates."enp1s0" = {
        content = ''
          [Match]
          Name=enp1s0

          [Network]
          DHCP=ipv4

          # manual ipv6 configuration
          Address=${config.sops.placeholder."fsn0_ipv6_address"}/${
            config.sops.placeholder."fsn0_ipv6_prefix_length"
          }
          Gateway=fe80::1
          DNS=2a01:4ff:ff00::add:1
          DNS=2a01:4ff:ff00::add:2
        '';
        owner = "systemd-network";
      };
      sops.secrets."fsn0_ipv6_address" = {
        terraformOutput.enable = true;
        reloadUnits = [ "systemd-networkd.service" ];
      };
      sops.secrets."fsn0_ipv6_prefix_length" = {
        terraformOutput.enable = true;
        reloadUnits = [ "systemd-networkd.service" ];
      };
    })

    # stateVersion
    { system.stateVersion = "24.11"; }
  ];
}
