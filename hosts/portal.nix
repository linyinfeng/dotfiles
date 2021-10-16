{ pkgs, config, suites, lib, ... }:

let
  dotTarHost = "tar.li7g.com";
  dotTarPort = 8001;
in
{
  imports =
    suites.server ++
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
        host = "portal.li7g.com";
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
      services.commit-notifier = {
        enable = true;
        cron = "0 */5 * * * *";
        tokenFile = config.age.secrets.commit-notifier-bot.path;
      };
      systemd.services.commit-notifier.serviceConfig.Restart = "on-failure";
      age.secrets.commit-notifier-bot.file = config.age.secrets-directory + /commit-notifier-bot.age;

      services.notify-failure.services = [
        "dot-tar"
        "commit-notifier"
      ];

      fileSystems."/" =
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
