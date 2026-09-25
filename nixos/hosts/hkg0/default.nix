{
  config,
  lib,
  ...
}:
{
  config = lib.mkMerge [
    {
      world.suites.overseaServer.enable = true;

      environment.global-persistence = {
        enable = true;
        root = "/persist";
      };

      boot.loader.grub.enable = true;
      boot.initrd.availableKernelModules = [
        "ata_piix"
        "sr_mod"
        "uhci_hcd"
        "virtio_blk"
        "virtio_pci"
      ];

      system.nproc = 2;
      services.telegraf-system.diskMountPoints = [
        "/boot"
        "/nix"
      ];
      services.zswap.enable = true;

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
              bios_grub = {
                priority = 0;
                size = "1M";
                type = "EF02";
              };
              boot = {
                priority = 100;
                size = "1G";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/boot";
                };
              };
              root = {
                priority = 200;
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
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
                      "@swap" = {
                        mountpoint = "/swap";
                        inherit mountOptions;
                        swap.swapfile.size = "2G";
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
    }

    {
      environment.etc."systemd/network/45-ens3.network".source = config.sops.templates."ens3".path;

      sops.secrets = {
        hkg0_network_address_v4 = {
          predefined.enable = true;
          reloadUnits = [ "systemd-networkd.service" ];
        };
        hkg0_network_address_v6 = {
          predefined.enable = true;
          reloadUnits = [ "systemd-networkd.service" ];
        };
        hkg0_network_gateway_v4 = {
          predefined.enable = true;
          reloadUnits = [ "systemd-networkd.service" ];
        };
        hkg0_network_gateway_v6 = {
          predefined.enable = true;
          reloadUnits = [ "systemd-networkd.service" ];
        };
        hkg0_network_subnet_v4 = {
          predefined.enable = true;
          reloadUnits = [ "systemd-networkd.service" ];
        };
        hkg0_network_subnet_v6 = {
          predefined.enable = true;
          reloadUnits = [ "systemd-networkd.service" ];
        };
      };

      sops.templates."ens3" = {
        content = ''
          [Match]
          Name=ens3

          [Network]
          Address=${config.sops.placeholder."hkg0_network_address_v4"}/${
            config.sops.placeholder."hkg0_network_subnet_v4"
          }
          Gateway=${config.sops.placeholder."hkg0_network_gateway_v4"}
          Address=${config.sops.placeholder."hkg0_network_address_v6"}/${
            config.sops.placeholder."hkg0_network_subnet_v6"
          }
          Gateway=${config.sops.placeholder."hkg0_network_gateway_v6"}
          DNS=8.8.8.8 1.1.1.1
        '';
        owner = "systemd-network";
      };
    }

    {
      topology.self.interfaces.ens3 = {
        network = "internet";
        renderer.hidePhysicalConnections = config.topology.tidy;
        physicalConnections = [
          (config.lib.topology.mkConnection "internet" "*")
        ];
      };
    }

    { system.stateVersion = "26.05"; }
  ];
}
