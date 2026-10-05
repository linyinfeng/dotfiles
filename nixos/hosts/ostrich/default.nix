{
  config,
  lib,
  ...
}:
{
  imports = [ ./_hardware.nix ];

  config = lib.mkMerge [
    {
      world = {
        profiles = {
          networking = {
            behind-fw.enable = true;
            fw-proxy.enable = true;
          };
          security.tpm.enable = true;
          services = {
            fwupd.enable = true;
            sunshine.enable = true;
          };
          users.yinfeng.enable = true;
        };
        suites = {
          games.enable = true;
          workstation.enable = true;
        };
      };

      boot.loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot = {
          enable = true;
          consoleMode = "max";
          configurationLimit = 10;
        };
        timeout = 10;
      };

      hardware.enableRedistributableFirmware = true;
      services.power-profiles-daemon.enable = true;
      # the wireless link is brought up by NetworkManager/iwd; do not let
      # systemd-networkd-wait-online stall the boot when there is no wired link
      systemd.network.wait-online.enable = false;

      home-manager.users.yinfeng =
        { ... }:
        {
          world.users.yinfeng.common.enable = true;
          world.suites.full.enable = true;
        };

      boot.initrd.systemd.tpm2.enable = true;
      boot.initrd.luks.devices."crypt-root".crypttabExtraOpts = [ "tpm2-device=auto" ];

      boot.tmp.useTmpfs = true;
      services.fstrim.enable = true;
      synchronize.users.yinfeng.enable = true;
      environment.global-persistence = {
        enable = true;
        root = "/persist";
      };
      services.btrfs.autoScrub = {
        enable = true;
        fileSystems = [ config.fileSystems."/persist".device ];
      };
      services.zswap.enable = true;
      services.telegraf-system.diskMountPoints = [
        "/boot" # vfat
        "/nix" # btrfs main pool
      ];

      disko.devices = {
        nodev."/" = {
          fsType = "tmpfs";
          mountOptions = [
            "defaults"
            "size=8G"
            "mode=755"
          ];
        };
        disk.main = {
          type = "disk";
          device = "/dev/disk/by-id/nvme-WDS100T1X0E-00AFY0_220367463012";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                priority = 0;
                start = "1MiB";
                size = "1G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [
                    "gid=wheel"
                    "dmask=007"
                    "fmask=117"
                  ];
                };
              };
              crypt-root = {
                priority = 100;
                start = "1025MiB";
                size = "640G";
                content = {
                  type = "luks";
                  name = "crypt-root";
                  settings = {
                    allowDiscards = true;
                    bypassWorkqueues = true;
                  };
                  content = {
                    type = "btrfs";
                    subvolumes =
                      let
                        mountOptions = [
                          "compress=zstd"
                        ];
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
                        "@swap" = {
                          mountpoint = "/swap";
                          inherit mountOptions;
                          swap.swapfile.size = "32G";
                        };
                      };
                  };
                };
              };
              windows-backup = {
                priority = 900;
                start = "656385MiB";
                size = "100%";
                type = "0700";
              };
            };
          };
        };
      };
      fileSystems = {
        "/nix".neededForBoot = true;
        "/persist".neededForBoot = true;
        "/var/log".neededForBoot = true;
      };

      system.nproc = 12;
    }

    # stateVersion
    { system.stateVersion = "26.05"; }
  ];
}
