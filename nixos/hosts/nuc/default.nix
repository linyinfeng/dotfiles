{
  config,
  lib,
  suites,
  profiles,
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
  imports =
    suites.server
    ++ suites.development
    ++ suites.virtualization
    ++ (with profiles; [
      boot.binfmt
      nix.hydra-builder-server
      nix.hydra-builder-client
      nix.nixbuild
      security.tpm
      security.audit
      i18n.input-method
      networking.network-manager
      networking.behind-fw
      networking.fw-proxy
      services.gnome-keyring
      services.transmission
      services.jellyfin
      services.samba
      services.nextcloud
      services.vlmcsd
      services.godns
      services.nginx
      services.acme
      services.smartd
      services.postgresql
      services.hydra
      services.fw-proxy-subscription
      services.fwupd
      # services.matrix-qq
      services.teamspeak
      programs.service-mail
      programs.tg-send
      users.yinfeng
      users.nianyi
    ])
    ++ [
      ./_minecraft-unmanaged
      ./_steam
    ];

  config = lib.mkMerge [
    {
      boot.loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot.enable = true;
      };
      hardware.enableRedistributableFirmware = true;

      services.thermald.enable = true;

      environment.global-persistence.enable = true;
      environment.global-persistence.root = "/persist";

      systemd.watchdog.runtimeTime = "60s";

      services.fstrim.enable = true;
      services.btrfs.autoScrub = {
        enable = true;
        fileSystems = [
          "/dev/disk/by-uuid/8b982fe4-1521-4a4d-aafc-af22c3961093"
          "/dev/mapper/crypt-mobile"
        ];
      };

      home-manager.users.yinfeng =
        { suites, ... }:
        {
          imports = suites.nonGraphical;
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
    { system.stateVersion = "25.05"; }
  ];
}
