{ pkgs, config, suites, lib, ... }:

let

  btrfsSubvol = device: subvol: extraConfig: lib.mkMerge [
    {
      inherit device;
      fsType = "btrfs";
      options = [ "subvol=${subvol}" "compress=zstd" ];
    }
    extraConfig
  ];
  btrfsSubvolMain = btrfsSubvol "/dev/disk/by-uuid/9f227a19-d570-449f-b4cb-0eecc5b2d227";

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
        "/var/lib/acme"
      ];

      environment.systemPackages = with pkgs; [
        tmux
      ];

      services.scheduled-reboot.enable = true;

      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
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

      services.nginx.virtualHosts."nuc.li7g.com" = {
        addSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://nuc.ts.li7g.com";
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
      fileSystems."/persist" = btrfsSubvolMain "@persist" { neededForBoot = true; };
      fileSystems."/var/log" = btrfsSubvolMain "@var-log" { neededForBoot = true; };
      fileSystems."/nix" = btrfsSubvolMain "@nix" { neededForBoot = true; };
      fileSystems."/swap" = btrfsSubvolMain "@swap" { };
      fileSystems."/boot" =
        {
          device = "/dev/disk/by-uuid/4a186796-5865-4b47-985c-9354adec09a4";
          fsType = "ext4";
        };
      swapDevices =
        [{
          device = "/swap/swapfile";
        }];
    }

    {
      networking = lib.mkIf (!config.system.is-vm) {
        useNetworkd = true;
        interfaces.ens3.useDHCP = true;
      };
    }
  ];
}
