{
  config,
  suites,
  profiles,
  lib,
  ...
}: let
  btrfsSubvol = device: subvol: extraConfig:
    lib.mkMerge [
      {
        inherit device;
        fsType = "btrfs";
        options = ["subvol=${subvol}" "compress=zstd" "x-gvfs-hide"];
      }
      extraConfig
    ];

  btrfsSubvolMain = btrfsSubvol "/dev/disk/by-uuid/9f227a19-d570-449f-b4cb-0eecc5b2d227";
in {
  imports =
    suites.mobileWorkstation
    ++ (with profiles; [
      boot.systemd-initrd
      boot.secure-boot
      nix.access-tokens
      nix.nixbuild
      nix.hydra-builder-server
      security.tpm
      networking.wireguard-home
      networking.behind-fw
      networking.fw-proxy
      virtualization.waydroid
      services.godns
      services.smartd
      services.nginx
      services.acme
      services.flatpak
      services.ssh-honeypot
      services.portal-client
      graphical.graphical-powersave-target
      programs.service-mail
      programs.tg-send
      hardware.backlight
      # TODO not supported on current kernel
      # hardware.sr-iov
      users.yinfeng
    ])
    ++ [
      ./_hardware.nix
    ];

  config = lib.mkMerge [
    {
      boot.loader.efi.canTouchEfiVariables = true;
      boot.loader.systemd-boot = {
        consoleMode = "auto";
      };

      boot.kernelModules = ["kvm-intel"];

      hardware.enableRedistributableFirmware = true;

      services.xserver.desktopManager.gnome.enable = true;
      services.power-profiles-daemon.enable = false;
      services.tlp = {
        enable = true;
        settings = {
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
          CPU_SCALING_GOVERNOR_ON_AC = "powersave";
          CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
          CPU_ENERGY_PERF_POLICY_ON_AC = "balance_power";
        };
      };
      services.logind.lidSwitchExternalPower = "ignore";

      services.fwupd = {
        enable = true;
        extraRemotes = ["lvfs-testing"];
      };

      boot.binfmt.emulatedSystems = [
        "aarch64-linux"
      ];

      services.fprintd.enable = true;

      networking.campus-network = {
        enable = true;
        auto-login.enable = true;
      };
      services.godns = {
        ipv6.settings = {
          domains = [
            {
              domain_name = "li7g.com";
              sub_domains = ["framework"];
            }
          ];
          ip_type = "IPv6";
          ip_interface = "enp0s13f0u4u4u5";
        };
      };

      home-manager.users.yinfeng = {suites, ...}: {
        imports = suites.full;
        programs.firefox.profiles.main.settings = {
          "media.ffmpeg.vaapi.enabled" = true;
          "media.navigator.mediadatadecoder_vpx_enabled" = true;
        };
      };

      boot.tmp.useTmpfs = true;
      services.fstrim.enable = true;
      environment.global-persistence.enable = true;
      environment.global-persistence.root = "/persist";

      services.btrfs.autoScrub = {
        enable = true;
        fileSystems = [
          "/dev/disk/by-uuid/9f227a19-d570-449f-b4cb-0eecc5b2d227"
        ];
      };

      boot.supportedFilesystems = ["ntfs"];
      boot.initrd.availableKernelModules = ["xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod"];
      boot.initrd.luks.devices = {
        crypt-root = {
          device = "/dev/disk/by-uuid/46fad3b7-6287-4bc2-a45e-0cdd053cbb85";
          allowDiscards = true;
        };
        crypt-swap = {
          device = "/dev/disk/by-uuid/bbf7e2ee-1a3b-4110-ac2a-1cd9169f2684";
          allowDiscards = true;
        };
      };
      fileSystems."/" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = ["defaults" "size=8G" "mode=755"];
      };
      fileSystems."/persist" = btrfsSubvolMain "@persist" {neededForBoot = true;};
      fileSystems."/var/log" = btrfsSubvolMain "@var-log" {neededForBoot = true;};
      fileSystems."/nix" = btrfsSubvolMain "@nix" {neededForBoot = true;};
      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/5C56-7693";
        fsType = "vfat";
        options = ["dmask=077" "fmask=177"];
      };
      services.zswap.enable = true;
      swapDevices = [
        {
          device = "/dev/disk/by-uuid/f9eb9a3a-2185-4f7e-83f0-76d88fa98557";
          discardPolicy = "once";
        }
      ];
    }

    # windows fonts
    (
      let
        windowsPart = "/dev/disk/by-uuid/A082C3A482C37CF2";
        windowsMountPoint = "/media/windows";
      in {
        users.groups.windows = {
          gid = config.ids.gids.windows;
        };
        fileSystems.${windowsMountPoint} = {
          device = windowsPart;
          fsType = "ntfs3";
          options = ["gid=${toString config.users.groups.windows.gid}" "ro" "fmask=337" "dmask=227"];
        };
        fonts.fontconfig.localConf = ''
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
          <fontconfig>
            <dir>${windowsMountPoint}/Windows/Fonts</dir>
          </fontconfig>
        '';
      }
    )

    # enchilada usb network
    {
      systemd.network.links."80-mobile-nixos-usb" = {
        matchConfig = {
          Property = [
            "ID_USB_VENDOR=Mobile_NixOS"
          ];
        };
        linkConfig = {
          Name = "mobile0";
        };
      };
      networking.networkmanager.unmanaged = [
        "mobile0"
      ];
      systemd.network.networks."80-mobile-nixos-usb" = {
        matchConfig = {
          Name = "mobile*";
        };
        address = ["172.16.42.2/24"];
        linkConfig = {
          ActivationPolicy = "bound";
        };
      };
    }

    # limit cpu quota for nix-daemon for laptop
    {
      systemd.services.nix-daemon.serviceConfig = {
        # 16 cores in total
        CPUQuota = "800%";
        CPUWeight = "idle";
      };
    }

    # stateVersion
    {
      system.stateVersion = "23.11";
    }
  ];
}
