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
      networking.as198764
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

    # portal
    {
      services.nginx.virtualHosts."portal.*" = {
        forceSSL = true;
        useACMEHost = "main";
        locations."/" = {
          root = pkgs.element-web;
        };
      };
      services.portal = {
        host = "portal.li7g.com";
        nginxVirtualHost = "portal.*";
        server.enable = true;
      };
    }

    (lib.mkIf (!config.system.is-vm) {
      networking.useNetworkd = true;
      systemd.network.networks."40-ens3" = {
        matchConfig = {
          Name = "ens3";
        };
        addresses = [
          {
            addressConfig = let
              address = assert lib.length hostData.endpoints_v6 == 1;
                lib.elemAt hostData.endpoints_v6 0;
            in {
              Address = "${address}/64";
            };
          }
        ];
        networkConfig = {
          DHCP = "yes";
        };
        routes = [
          {
            routeConfig = {
              Gateway = "2404:8c80:85:1011::1";
            };
          }
        ];
      };
    })
  ];
}
