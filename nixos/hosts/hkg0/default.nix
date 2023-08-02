{
  config,
  suites,
  profiles,
  lib,
  pkgs,
  modulesPath,
  ...
}: let
  hostName = config.networking.hostName;
  hostData = config.lib.self.data.hosts.${hostName};
in {
  imports =
    suites.server
    ++ (with profiles; [
      programs.tg-send
      services.nginx
      services.acme
      services.notify-failure
      services.portal-server
    ])
    ++ [
      (modulesPath + "/profiles/qemu-guest.nix")
    ];

  config = lib.mkMerge [
    {
      boot.loader.grub = {
        enable = true;
        device = "/dev/vda";
      };
      boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "virtio_pci" "virtio_blk"];

      boot.tmp.cleanOnBoot = true;
      environment.global-persistence.enable = false;

      fileSystems."/" = {
        device = "/dev/vda1";
        fsType = "ext4";
      };
      swapDevices = [{device = "/dev/vda2";}];
    }

    (lib.mkIf (!config.system.is-vm) {
      systemd.network.networks."40-ens3" = {
        matchConfig = {
          Name = "ens3";
        };
        addresses = [
          {
            addressConfig = let
              address = assert lib.length hostData.endpoints_v4 == 1;
                lib.elemAt hostData.endpoints_v4 0;
            in {
              Address = "${address}/25"; # netmask 255.255.255.128
            };
          }
          {
            addressConfig = let
              address = assert lib.length hostData.endpoints_v6 == 1;
                lib.elemAt hostData.endpoints_v6 0;
            in {
              Address = "${address}/64";
            };
          }
        ];
        dns = [
          "8.8.8.8"
          "8.8.4.4"
          "2001:4860:4860:0:0:0:0:8888"
          "2001:4860:4860:0:0:0:0:8844"
        ];
        routes = [
          {
            routeConfig = {
              Gateway = "2404:8c80:85:1011::1";
            };
          }
          {
            routeConfig = {
              Gateway = "149.104.16.126";
            };
          }
        ];
      };
    })
  ];
}
