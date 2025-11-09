{
  config,
  suites,
  profiles,
  lib,
  modulesPath,
  ...
}:
let
  inherit (config.networking) hostName;
  hostData = config.lib.self.data.hosts.${hostName};
in
{
  imports =
    suites.overseaServer
    ++ (with profiles; [
      programs.tg-send
      services.nginx
      services.acme
    ])
    ++ [ (modulesPath + "/profiles/qemu-guest.nix") ];

  config = lib.mkMerge [
    {
      boot.loader.grub.enable = true;
      boot.initrd.availableKernelModules = [
        "ata_piix"
        "uhci_hcd"
        "virtio_pci"
        "sr_mod"
        "virtio_blk"
      ];
      boot.kernelModules = [ "kvm-intel" ];

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
        disk.main = {
          type = "disk";
          device = "/dev/vda";
          content = {
            type = "gpt";
            partitions = {
              bios = {
                size = "1M";
                type = "EF02"; # grub MBR
              };
              efi = {
                size = "1024M"; # total size 1024 MiB
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
              root = {
                size = "100%";
                content = {
                  type = "btrfs";
                  subvolumes = {
                    "@persist" = {
                      mountpoint = "/persist";
                      mountOptions = [ "compress=zstd" ];
                    };
                    "@var-log" = {
                      mountpoint = "/var/log";
                      mountOptions = [ "compress=zstd" ];
                    };
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd" ];
                    };
                    "@tmp" = {
                      mountpoint = "/tmp";
                      mountOptions = [ "compress=zstd" ];
                    };
                    "@swap" = {
                      mountpoint = "/swap";
                      mountOptions = [ "compress=zstd" ];
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
      swapDevices = [
        {
          device = "/swap/swapfile";
          size = 4096;
        }
      ];

      system.nproc = 1;
    }

    (lib.mkIf (!config.system.is-vm) {
      systemd.network.networks."40-ens3" = {
        matchConfig = {
          Name = "ens3";
        };
        networkConfig = {
          IPv6AcceptRA = false;
        };
        addresses = [
          {
            Address =
              let
                address =
                  assert lib.length hostData.endpoints_v4 == 1;
                  lib.elemAt hostData.endpoints_v4 0;
              in
              "${address}/26";
          }
          {
            Address =
              let
                address =
                  assert lib.length hostData.endpoints_v6 == 1;
                  lib.elemAt hostData.endpoints_v6 0;
              in
              "${address}/64";
          }
        ];
        dns = [
          "8.8.8.8"
          "8.8.4.4"
        ];
        routes = [
          { Gateway = "142.171.74.65"; }
          { Gateway = "fe80::217:dfff:feb3:a800"; }
        ];
      };
    })

    # topology
    {
      topology.self.interfaces.ens3 = {
        network = "internet";
        renderer.hidePhysicalConnections = config.topology.tidy;
        physicalConnections = [
          (config.lib.topology.mkConnection "internet" "*")
        ];
      };
    }

    # stateVersion
    { system.stateVersion = "25.05"; }
  ];
}
