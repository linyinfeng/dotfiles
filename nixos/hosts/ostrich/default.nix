{
  config,
  lib,
  ...
}:
{
  imports = [
    ./_hardware.nix
    ./_image.nix
  ];

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
            acme.enable = true;
            garage.enable = true;
            llama-cpp.enable = true;
            nginx.enable = true;
            sunshine.enable = true;
          };
          nix.hydra-builder.enable = true;
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
      # NetworkManager manages the guest network interface.
      systemd.network.wait-online.enable = false;
      networking.fw-proxy.allowedIPv4Subnets = [
        config.lib.self.data.subnets.ostrich-incus.cidr
      ];

      home-manager.users.yinfeng =
        { ... }:
        {
          world.users.yinfeng.common.enable = true;
          world.suites.full.enable = true;
        };

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
          device = "/dev/vda";
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
                    "gid=${toString config.users.groups.wheel.gid}"
                    "dmask=007"
                    "fmask=117"
                  ];
                };
              };
              root = {
                priority = 100;
                start = "1025MiB";
                size = "100%";
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
