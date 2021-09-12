{ config, suites, lib, ... }:

let
  dot-tar-host = "tar.li7g.com";
  dot-tar-port = 8001;
in
{
  imports =
    suites.server;
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
      boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];

      boot.tmpOnTmpfs = true;

      services.scheduled-reboot.enable = true;

      services.portal = {
        host = "portal.li7g.com";
        server.enable = true;
      };

      services.dot-tar = {
        enable = true;
        config = {
          release = {
            port = dot-tar-port;
            authority_allow_list = [
              "github.com"
            ];
          };
        };
      };

      services.caddy = {
        config = ''
          ${dot-tar-host} {
            log {
              output stdout
            }
            reverse_proxy localhost:${toString dot-tar-port}
          }
        '';
      };

      networking = lib.mkIf (!config.system.is-vm-test) {
        useNetworkd = true;
        interfaces.ens3.useDHCP = true;
      };

      fileSystems."/" =
        {
          device = "/dev/disk/by-uuid/c02e1983-731b-4aab-96dc-73e594901c80";
          fsType = "ext4";
        };

      swapDevices =
        [{ device = "/dev/disk/by-uuid/961406a7-4dac-4d45-80e9-ef9b0d4fab99"; }];
    }

    (lib.mkIf config.system.is-vm-test {
      services.nginx.enable = lib.mkForce false;
    })
  ];
}
