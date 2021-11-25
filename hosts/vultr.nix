{ pkgs, config, suites, lib, ... }:

let
  portalHost = "portal.li7g.com";
  dotTarHost = "tar.li7g.com";
  dotTarPort = 8001;
in
{
  imports =
    suites.server ++
    suites.telegram-send ++
    suites.notify-failure ++
    suites.acme;

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
      environment.global-persistence.enable = true;
      environment.global-persistence.root = "/nix/persist";
      environment.global-persistence.directories = [
        "/var/log"
        "/var/lib/acme"
      ];

      environment.systemPackages = with pkgs; [
        tmux
      ];

      services.scheduled-reboot.enable = true;

      services.nginx = {
        enable = true;
      };
      networking.firewall.allowedTCPPorts = [ 80 443 ];
      services.nginx.virtualHosts.${config.services.portal.host} = {
        addSSL = true;
        enableACME = true;
      };
      services.portal = {
        host = portalHost;
        server.enable = true;
      };
      services.nginx.virtualHosts.${dotTarHost} = {
        addSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString dotTarPort}";
        };
      };
      services.dot-tar = {
        enable = true;
        config = {
          release = {
            port = dotTarPort;
            authority_allow_list = [
              "github.com"
            ];
          };
        };
      };

      services.notify-failure.services = [
        "dot-tar"
      ];

      fileSystems."/" =
        {
          device = "tmpfs";
          fsType = "tmpfs";
          options = [ "defaults" "size=2G" "mode=755" ];
        };
      fileSystems."/nix" =
        {
          device = "/dev/disk/by-uuid/c02e1983-731b-4aab-96dc-73e594901c80";
          fsType = "ext4";
        };

      swapDevices =
        [{ device = "/dev/disk/by-uuid/961406a7-4dac-4d45-80e9-ef9b0d4fab99"; }];
    }

    {
      networking = lib.mkIf (!config.system.is-vm) {
        useNetworkd = true;
        interfaces.ens3.useDHCP = true;
      };
    }
  ];
}
