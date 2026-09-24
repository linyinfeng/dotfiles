{
  config,
  lib,
  pkgs,
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

  btrfsSubvolMain = btrfsSubvol "/dev/disk/by-uuid/8b982fe4-1521-4a4d-aafc-af22c3961093";
  btrfsSubvolMobile = btrfsSubvol "/dev/mapper/crypt-mobile";
in
{
  imports = [
    ./_minecraft-unmanaged
    ./_steam
    ./_home-assistant
  ];

  config = lib.mkMerge [
    {
      world = {
        profiles = {
          boot.binfmt.enable = true;
          i18n.input-method.enable = true;
          networking = {
            behind-fw.enable = true;
            fw-proxy.enable = true;
            network-manager.enable = true;
          };
          nix = {
            hydra-builder-client.enable = true;
            hydra-builder-server.enable = true;
            nixbuild.enable = true;
          };
          programs = {
            service-mail.enable = true;
            tg-send.enable = true;
          };
          security = {
            audit.enable = true;
            tpm.enable = true;
          };
          services = {
            acme.enable = true;
            cache-overlay.enable = true;
            forgejo.enable = true;
            frp-server.enable = true;
            fw-proxy-subscription.enable = true;
            fwupd.enable = true;
            gnome-keyring.enable = true;
            godns.enable = true;
            hydra.enable = true;
            jellyfin.enable = true;
            nextcloud.enable = true;
            nginx.enable = true;
            postgresql.enable = true;
            samba.enable = true;
            smartd.enable = true;
            teamspeak.enable = true;
            transmission.enable = true;
            tsukkomi.enable = true;
            vlmcsd.enable = true;
          };
          users = {
            agent.enable = true;
            yinfeng.enable = true;
          };
        };
        suites = {
          development.enable = true;
          server.enable = true;
          virtualization.enable = true;
        };
      };
    }

    {
      boot.loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot.enable = true;
      };
      hardware.enableRedistributableFirmware = true;

      environment.global-persistence.enable = true;
      environment.global-persistence.root = "/persist";

      systemd.settings.Manager.RuntimeWatchdogSec = "60s";

      # TODO: drop when nixpkgs hydra bundles nix >= 2.53
      # match the nix bundled by hydra so evaluator/queue-runner see the same version
      nix.package = lib.mkForce pkgs.hydra.passthru.nix;

      services.fstrim.enable = true;
      services.btrfs.autoScrub = {
        enable = true;
        fileSystems = [
          "/dev/disk/by-uuid/8b982fe4-1521-4a4d-aafc-af22c3961093"
          "/dev/mapper/crypt-mobile"
        ];
      };

      home-manager.users.yinfeng =
        { ... }:
        {
          world.users.yinfeng.common.enable = true;
          world.suites.nonGraphical.enable = true;
        };

      boot.initrd.availableKernelModules = [
        "xhci_pci"
        "thunderbolt"
        "vmd"
        "ahci"
        "nvme"
        "usbhid"
        "uas"
        "sd_mod"
      ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.extraModprobeConfig = ''
        options kvm-intel nested=1
      '';
      boot.initrd.luks.devices = {
        crypt-mobile = {
          device = "/dev/disk/by-uuid/b456f27c-b0a1-4b1e-8f2b-91f1826ae51c";
          allowDiscards = true;
        };
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
      boot.tmp = {
        # CI builds requires a lot of space
        useTmpfs = false;
        cleanOnBoot = true;
      };
      fileSystems."/nix" = btrfsSubvolMain "@nix" { neededForBoot = true; };
      fileSystems."/persist" = btrfsSubvolMain "@persist" { neededForBoot = true; };
      fileSystems."/var/log" = btrfsSubvolMain "@var-log" { neededForBoot = true; };
      fileSystems."/swap" = btrfsSubvolMain "@swap" { };
      fileSystems."/tmp" = btrfsSubvolMain "@tmp" { };
      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/C9A4-3DE6";
        fsType = "vfat";
        options = [
          "gid=wheel"
          "dmask=007"
          "fmask=117"
        ];
      };
      services.zswap.enable = true;
      swapDevices = [ { device = "/swap/swapfile"; } ];
      fileSystems."/var/lib/transmission" = btrfsSubvolMobile "@bittorrent" { };
      fileSystems."/media/data" = btrfsSubvolMobile "@data" { };

      system.nproc = 8;
    }

    # godns
    {
      services.godns-multi = {
        ipv4.settings = {
          domains = [
            {
              domain_name = "li7g.com";
              sub_domains = [ "nuc" ];
            }
          ];
          ip_type = "IPv4";
          ip_urls = [
            "https://myip.biturl.top"
            "https://ipecho.net/plain"
            "https://api-ipv4.ip.sb/ip"
          ];
        };
        ipv6.settings = {
          domains = [
            {
              domain_name = "li7g.com";
              sub_domains = [ "nuc" ];
            }
          ];
          ip_type = "IPv6";
          ipv6_urls = [
            "https://myip.biturl.top"
            "https://ipecho.net/plain"
            "https://api-ipv6.ip.sb/ip"
          ];
        };
      };
    }

    # nginx
    {
      services.nginx = {
        defaultListen = [
          {
            addr = "0.0.0.0";
            port = config.ports.http;
            ssl = false;
          }
          {
            addr = "0.0.0.0";
            port = config.ports.https;
            ssl = true;
          }
          {
            addr = "0.0.0.0";
            port = config.ports.http-alternative;
            ssl = false;
          }
          {
            addr = "0.0.0.0";
            port = config.ports.https-alternative;
            ssl = true;
          }
          {
            addr = "[::]";
            port = config.ports.http;
            ssl = false;
          }
          {
            addr = "[::]";
            port = config.ports.https;
            ssl = true;
          }
          {
            addr = "[::]";
            port = config.ports.http-alternative;
            ssl = false;
          }
          {
            addr = "[::]";
            port = config.ports.https-alternative;
            ssl = true;
          }
        ];
        virtualHosts."nuc.*" = {
          serverAliases = [ "nuc-proxy.*" ];
          locations."/" = {
            root = ./_www;
          };
        };
      };
      networking.firewall.allowedTCPPorts = with config.ports; [
        http-alternative
        https-alternative
      ];
      networking.firewall.allowedUDPPorts = with config.ports; [ https-alternative ];
    }

    # topology
    {
      topology.self.interfaces.enp88s0 = {
        network = "home";
        physicalConnections = [
          (config.lib.topology.mkConnection "home-room-switch" "lan2")
        ];
      };
    }

    # stateVersion
    { system.stateVersion = "26.05"; }
  ];
}
