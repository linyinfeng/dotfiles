{ pkgs, config, suites, lib, modulesPath, ... }:
let

  btrfsSubvol = device: subvol: extraConfig: lib.mkMerge [
    {
      inherit device;
      fsType = "btrfs";
      options = [ "subvol=${subvol}" "compress=zstd" ];
    }
    extraConfig
  ];

  btrfsSubvolMain = btrfsSubvol "/dev/disk/by-uuid/c0e72722-18c2-4250-9034-676287478998";

  portalHost = "portal.li7g.com";
  dotTarHost = "tar.li7g.com";
  dotTarPort = 8001;
in
{
  imports =
    suites.server ++
    suites.telegram-send ++
    suites.notify-failure ++
    suites.acme ++ [
      (modulesPath + "/profiles/qemu-guest.nix")
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
      boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
      boot.kernelModules = [ "kvm-amd" ];

      boot.tmpOnTmpfs = true;

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
      services.commit-notifier = {
        enable = true;
        cron = "0 */5 * * * *";
        tokenFile = config.sops.secrets."telegram-bot/commit-notifier".path;
      };
      systemd.services.commit-notifier.serviceConfig.Restart = "on-failure";
      sops.secrets."telegram-bot/commit-notifier" = { };

      services.notify-failure.services = [
        "dot-tar"
        "commit-notifier"
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
          device = "/dev/disk/by-uuid/f8d738d7-a2be-448f-a521-2b2a408d2572";
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
