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
      services.postgresql
    ])
    ++ [
      "${modulesPath}/profiles/qemu-guest.nix"
      ./matrix
      ./mastodon
      ./maddy
    ];

  config = lib.mkMerge [
    {
      i18n.defaultLocale = "en_US.UTF-8";
      console.keyMap = "us";
      time.timeZone = "Asia/Shanghai";

      boot.loader = {
        # efi support of hetzner is in beta
        # no efi variables to touch
        efi.canTouchEfiVariables = false;
        grub = {
          enable = true;
          efiSupport = true;
          version = 2;
          device = "/dev/sda";
        };
      };
      boot.initrd.availableKernelModules = ["ahci" "xhci_pci" "virtio_pci" "sd_mod" "sr_mod"];

      boot.tmpOnTmpfs = true;
      services.fstrim.enable = true;
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
        device = "/dev/disk/by-uuid/5C56-7693";
        fsType = "vfat";
      };
      swapDevices = [
        {
          device = "/swap/swapfile";
        }
      ];
    }

    # well-known
    {
      services.nginx.virtualHosts."li7g.com" = {
        forceSSL = true;
        useACMEHost = "main";
        # matrix
        locations."/.well-known/matrix/server".extraConfig = ''
          default_type application/json;
          return 200 '{ "m.server": "matrix.li7g.com:443" }';
        '';
        locations."/.well-known/matrix/client".extraConfig = ''
          add_header Access-Control-Allow-Origin '*';
          default_type application/json;
          return 200 '{ "m.homeserver": { "base_url": "https://matrix.li7g.com" } }';
        '';
        # mastodon
        locations."/.well-known/host-meta".extraConfig = ''
          return 301 https://mastodon.li7g.com$request_uri;
        '';
        locations."/.well-known/webfinger".extraConfig = ''
          return 301 https://mastodon.li7g.com$request_uri;
        '';
      };
    }

    # networking
    (lib.mkIf (!config.system.is-vm) {
      networking.useNetworkd = true;
      environment.etc."systemd/network/45-enp1s0.network".source =
        config.sops.templates."enp1s0".path;
      sops.templates."enp1s0" = {
        content = ''
          [Match]
          Name=enp1s0

          [Network]
          DHCP=ipv4

          # manual ipv6 configuration
          Address=${config.sops.placeholder."hil0_ipv6_address"}/${config.sops.placeholder."hil0_ipv6_prefix_length"}
          Gateway=fe80::1
          DNS=2a01:4ff:ff00::add:1
          DNS=2a01:4ff:ff00::add:2
        '';
        owner = "systemd-network";
      };
      sops.secrets."hil0_ipv6_address" = {
        sopsFile = config.sops-file.terraform;
        restartUnits = ["systemd-networkd.service"];
      };
      sops.secrets."hil0_ipv6_prefix_length" = {
        sopsFile = config.sops-file.terraform;
        restartUnits = ["systemd-networkd.service"];
      };
    })
  ];
}
