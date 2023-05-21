{
  config,
  suites,
  profiles,
  lib,
  pkgs,
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

    {
      networking = lib.mkIf (!config.system.is-vm) {
        useNetworkd = true;
        interfaces.ens3.useDHCP = true;
      };
    }
  ];
}
