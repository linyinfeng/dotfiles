{
  config,
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
  config = lib.mkMerge [
    {
      world.suites = {
        development.enable = true;
        overseaServer.enable = true;
      };

      # keep-sorted start
      world.profiles = {
        i18n.input-method.enable = true;
        programs.tg-send.enable = true;
        services = {
          atuin.enable = true;
          bird-lg.enable = true;
          commit-notifier.enable = true;
          dn42-site.enable = true;
          dot-tar.enable = true;
          dotfiles-update-trigger.enable = true;
          frp-server.enable = true;
          garage.enable = true;
          gitlab-runner-sicp.enable = true;
          hledger-web.enable = true;
          http-test.enable = true;
          maddy.enable = true;
          mastodon.enable = true;
          matrix.enable = true;
          nuc-proxy.enable = true;
          oranc.enable = true;
          pastebin.enable = true;
          pgp-public-key-web.enable = true;
          pocket-id.enable = true;
          portal-server.enable = true;
          postgresql.enable = true;
          prebuilt-zip.enable = true;
          sicp-staging.enable = true;
          static-file-hosting.enable = true;
          telegraf-http.enable = true;
          vaultwarden.enable = true;
          well-known.enable = true;
        };
        users.yinfeng.enable = true;
        virtualization.podman.enable = true;
      };
      # keep-sorted end
    }

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
      services.telegraf-system.diskMountPoints = [
        "/boot" # ext4
        "/nix" # btrfs main pool
      ];
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
        { ... }:
        {
          world.users.yinfeng.common.enable = true;
          world.suites.nonGraphical.enable = true;
        };
    }

    # stateVersion
    { system.stateVersion = "26.05"; }
  ];
}
