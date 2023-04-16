{
  pkgs,
  config,
  suites,
  profiles,
  lib,
  modulesPath,
  ...
}: let
  btrfsSubvol = device: subvol: extraConfig:
    lib.mkMerge [
      {
        inherit device;
        fsType = "btrfs";
        options = ["subvol=${subvol}" "compress=zstd"];
      }
      extraConfig
    ];
  btrfsSubvolMain = btrfsSubvol "/dev/disk/by-uuid/9f227a19-d570-449f-b4cb-0eecc5b2d227";
in {
  imports =
    suites.server
    ++ (with profiles; [
      programs.tg-send
      services.nginx
      services.acme
      services.notify-failure
      services.ace-bot
    ])
    ++ [
      (modulesPath + "/profiles/qemu-guest.nix")
      ./cache-overlay.nix
      ./pgp
    ];

  config = lib.mkMerge [
    {
      i18n.defaultLocale = "en_US.UTF-8";
      console.keyMap = "us";
      time.timeZone = "Asia/Shanghai";

      boot.loader.grub = {
        enable = true;
        version = 2;
        device = "/dev/vda";
      };
      boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk"];

      boot.tmp.useTmpfs = true;
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

      fileSystems."/" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = ["defaults" "size=2G" "mode=755"];
      };
      fileSystems."/persist" = btrfsSubvolMain "@persist" {neededForBoot = true;};
      fileSystems."/var/log" = btrfsSubvolMain "@var-log" {neededForBoot = true;};
      fileSystems."/nix" = btrfsSubvolMain "@nix" {neededForBoot = true;};
      fileSystems."/swap" = btrfsSubvolMain "@swap" {};
      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/4a186796-5865-4b47-985c-9354adec09a4";
        fsType = "ext4";
      };
      swapDevices = [
        {
          device = "/swap/swapfile";
        }
      ];
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

    # dot-tar
    {
      services.nginx.virtualHosts."tar.*" = {
        forceSSL = true;
        useACMEHost = "main";
        locations."/" = {
          proxyPass = "http://localhost:${toString config.ports.dot-tar}";
        };
      };
      services.dot-tar = {
        enable = true;
        config = {
          release = {
            port = config.ports.dot-tar;
            authority_allow_list = [
              "github.com"
            ];
          };
        };
      };

      services.notify-failure.services = [
        "dot-tar"
      ];
    }

    # nuc-proxy
    {
      services.nginx.upstreams."nuc".servers = {
        "nuc.ts.li7g.com:${toString config.ports.https}" = {};
        "nuc.zt.li7g.com:${toString config.ports.https}" = {backup = true;};
        "nuc.li7g.com:${toString config.ports.https-alternative}" = {backup = true;};
      };
      services.nginx.virtualHosts."nuc-proxy.*" = {
        forceSSL = true;
        useACMEHost = "main";
        locations."/" = {
          proxyPass = "https://nuc";
        };
      };
    }

    # oranc
    {
      services.oranc = {
        enable = true;
        listen = "127.0.0.1:${toString config.ports.oranc}";
      };
      services.nginx.virtualHosts."oranc.*" = {
        forceSSL = true;
        useACMEHost = "main";
        locations."/" = {
          proxyPass = "http://${config.services.oranc.listen}";
        };
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
