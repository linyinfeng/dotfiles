{
  config,
  suites,
  profiles,
  lib,
  ...
}:
let
  btrfsSubvol =
    device: subvol: extraConfig:
    lib.mkMerge [
      {
        inherit device;
        fsType = "btrfs";
        options = [
          "subvol=${subvol}"
          "compress=zstd"
        ];
      }
      extraConfig
    ];

  btrfsSubvolMain = btrfsSubvol "/dev/disk/by-uuid/9f227a19-d570-449f-b4cb-0eecc5b2d227";
in
{
  imports =
    suites.overseaServer
    ++ suites.development
    ++ (with profiles; [
      programs.tg-send
      services.nginx
      services.acme
      services.postgresql
      services.minio
      services.vaultwarden
      services.gitweb
      # services.seafile
      services.commit-notifier
      services.pastebin
      services.http-test
      services.static-file-hosting
      services.telegraf-http
      services.prebuilt-zip
      services.hledger-web
      # services.sicp-staging
      services.rabbitmq
      services.mongodb
      services.gitlab-runner-sicp
      i18n.input-method
      virtualization.podman
      users.yinfeng
    ]);

  config = lib.mkMerge [
    {
      boot.loader.grub = {
        enable = true;
        device = "/dev/xvda";
      };
      boot.initrd.availableKernelModules = [
        "ata_piix"
        "uhci_hcd"
        "sr_mod"
        "xen_blkfront"
      ];

      boot.tmp.useTmpfs = true;
      environment.global-persistence.enable = true;
      environment.global-persistence.root = "/persist";

      services.btrfs.autoScrub = {
        enable = true;
        fileSystems = [ "/dev/disk/by-uuid/9f227a19-d570-449f-b4cb-0eecc5b2d227" ];
      };

      fileSystems."/" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [
          "defaults"
          "size=2G"
          "mode=755"
        ];
      };
      fileSystems."/persist" = btrfsSubvolMain "@persist" { neededForBoot = true; };
      fileSystems."/var/log" = btrfsSubvolMain "@var-log" { neededForBoot = true; };
      fileSystems."/nix" = btrfsSubvolMain "@nix" { neededForBoot = true; };
      fileSystems."/swap" = btrfsSubvolMain "@swap" { };
      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/4a186796-5865-4b47-985c-9354adec09a4";
        fsType = "ext4";
      };
      services.zswap.enable = true;
      swapDevices = [ { device = "/swap/swapfile"; } ];

      system.nproc = 4;
    }

    (lib.mkIf (!config.system.is-vm) {
      environment.etc."systemd/network/45-enX0.network".source = config.sops.templates."enX0".path;
      sops.secrets."mtl0_network_address" = {
        predefined.enable = true;
        reloadUnits = [ "systemd-networkd.service" ];
      };
      sops.secrets."mtl0_network_subnet" = {
        predefined.enable = true;
        reloadUnits = [ "systemd-networkd.service" ];
      };
      sops.secrets."mtl0_network_gateway" = {
        predefined.enable = true;
        reloadUnits = [ "systemd-networkd.service" ];
      };
      sops.templates."enX0" = {
        content = ''
          [Match]
          Name=enX0

          [Network]
          Address=${config.sops.placeholder."mtl0_network_address"}/${
            config.sops.placeholder."mtl0_network_subnet"
          }
          Gateway=${config.sops.placeholder."mtl0_network_gateway"}
          DNS=8.8.8.8 8.8.4.4

          Tunnel=he-ipv6
        '';
        owner = "systemd-network";
      };

      # HE Tunnel
      environment.etc."systemd/network/50-he-ipv6.netdev".source =
        config.sops.templates."he-ipv6-netdev".path;
      sops.templates."he-ipv6-netdev" = {
        content = ''
          [NetDev]
          Name=he-ipv6
          Kind=sit
          MTUBytes=1480

          [Tunnel]
          Remote=216.66.38.58
          Local=${config.sops.placeholder."mtl0_network_address"}
          TTL=255
        '';
        owner = "systemd-network";
      };
      systemd.network.networks."50-he-ipv6" = {
        matchConfig = {
          Name = "he-ipv6";
        };
        address = [ "2001:470:1c:4ff::2/64" ];
        routes = [ { Gateway = "::"; } ];
      };
    })

    # topology
    {
      topology.self.interfaces = {
        enX0 = {
          network = "internet";
          renderer.hidePhysicalConnections = config.topology.tidy;
          physicalConnections = [
            (config.lib.topology.mkConnection "internet" "*")
          ];
        };
        he-ipv6 = {
          network = "internet";
          renderer.hidePhysicalConnections = config.topology.tidy;
          physicalConnections = [
            (config.lib.topology.mkConnection "internet" "*")
          ];
        };
      };
    }

    # user
    {
      home-manager.users.yinfeng =
        { suites, ... }:
        {
          imports = suites.nonGraphical;
        };
    }

    # stateVersion
    { system.stateVersion = "25.11"; }
  ];
}
