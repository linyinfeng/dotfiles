{
  config,
  suites,
  profiles,
  lib,
  ...
}:
{
  imports =
    suites.mobileWorkstation
    ++ suites.games
    ++ (with profiles; [
      boot.plymouth
      boot.secure-boot
      boot.lanzaboote-uki
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
      services.ollama
      services.open-webui
      graphical.graphical-powersave-target
      programs.service-mail
      programs.tg-send
      hardware.backlight
      users.yinfeng
    ])
    ++ [
      ./_hardware.nix
      # TODO wait for https://github.com/NixOS/nixpkgs/issues/375730
      # ./_nvidia.nix
    ];

  config = lib.mkMerge [
    {
      boot.loader.efi.canTouchEfiVariables = true;
      boot.loader.systemd-boot = {
        consoleMode = "max";
        configurationLimit = 10;
      };
      boot.loader.timeout = 10;

      # kernel tweaks
      # boot.kernelModuleSigning.enable = true;
      # boot.kernelLockdown = true;

      hardware.enableRedistributableFirmware = true;

      services.xserver.desktopManager.gnome.enable = true;
      services.power-profiles-daemon.enable = false;
      services.tlp = {
        enable = true;
        settings = {
          CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
          PLATFORM_PROFILE_ON_BAT = "low-power";
          CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
          PLATFORM_PROFILE_ON_AC = "balanced";
        };
      };
      services.logind.lidSwitchExternalPower = "ignore";

      services.fwupd = {
        enable = true;
        extraRemotes = [ "lvfs-testing" ];
      };

      networking.campus-network = {
        enable = true;
        auto-login.enable = true;
      };
      services.godns = {
        ipv6.settings = {
          domains = [
            {
              domain_name = "li7g.com";
              sub_domains = [ "framework" ];
            }
          ];
          ip_type = "IPv6";
          ip_interface = "enp0s13f0u4u4u5";
        };
      };

      home-manager.users.yinfeng =
        { suites, profiles, ... }:
        {
          imports =
            suites.full
            ++ (with profiles; [
              music
              blender
            ]);
          programs.firefox.profiles.main.settings = {
            "media.ffmpeg.vaapi.enabled" = true;
            "media.navigator.mediadatadecoder_vpx_enabled" = true;
          };
        };
      # for ardour
      security.pam.loginLimits = [
        {
          domain = "yinfeng";
          item = "memlock";
          type = "-";
          value = "unlimited"; # 1 GiB
        }
        {
          domain = "yinfeng";
          item = "rtprio";
          type = "-";
          value = "unlimited";
        }
      ];

      boot.tmp.useTmpfs = true;
      services.fstrim.enable = true;
      environment.global-persistence.enable = true;
      environment.global-persistence.root = "/persist";

      services.btrfs.autoScrub = {
        enable = true;
        fileSystems = [ config.fileSystems."/persist".device ];
      };

      disko.devices = {
        nodev."/" = {
          fsType = "tmpfs";
          mountOptions = [
            "defaults"
            "size=8G"
            "mode=755"
          ];
        };
        disk.main = {
          type = "disk";
          device = "/dev/nvme0n1";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                priority = 0;
                size = "1G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [
                    "gid=wheel"
                    "dmask=007"
                    "fmask=117"
                  ];
                };
              };
              crypt-root = {
                priority = 100;
                size = "1T";
                content = {
                  type = "luks";
                  name = "crypt-root";
                  settings = {
                    allowDiscards = true;
                    bypassWorkqueues = true;
                  };
                  content = {
                    type = "btrfs";
                    subvolumes =
                      let
                        mountOptions = [
                          "compress=zstd"
                          "x-gvfs-hide"
                        ];
                      in
                      {
                        "@persist" = {
                          mountpoint = "/persist";
                          inherit mountOptions;
                        };
                        "@var-log" = {
                          mountpoint = "/var/log";
                          inherit mountOptions;
                        };
                        "@nix" = {
                          mountpoint = "/nix";
                          inherit mountOptions;
                        };
                        "@swap" = {
                          mountpoint = "/swap";
                          inherit mountOptions;
                          swap.swapfile.size = "32G";
                        };
                      };
                  };
                };
              };
              windows = {
                priority = 900;
                size = "512G";
                content = {
                  type = "filesystem";
                  format = "ntfs";
                };
              };
              # reserved = {
              #   priority = 1000;
              #   size = "100%";
              # };
            };
          };
        };
      };
      fileSystems."/persist".neededForBoot = true;
      fileSystems."/var/log".neededForBoot = true;
      services.zswap.enable = true;

      boot.supportedFilesystems = [ "ntfs" ];
      boot.initrd.availableKernelModules = [
        "xhci_pci"
        "thunderbolt"
        "nvme"
        "usb_storage"
        "usbhid"
        "sd_mod"
      ];

      system.nproc = 16;
    }

    # ollama
    {
      # slower than CPU
      # services.ollama = {
      #   acceleration = "rocm";
      #   environmentVariables = {
      #     ROC_ENABLE_PRE_VEGA = "1";
      #     # TODO remove after ollama support gfx1103
      #     # https://github.com/ROCm/ROCm/discussions/2631
      #     HSA_OVERRIDE_GFX_VERSION="11.0.2";
      #   };
      # };
    }

    # enchilada usb network
    {
      systemd.network.links."80-mobile-nixos-usb" = {
        matchConfig = {
          Property = [ "ID_USB_VENDOR=Mobile_NixOS" ];
        };
        linkConfig = {
          Name = "mobile0";
        };
      };
      networking.networkmanager.unmanaged = [ "mobile0" ];
      systemd.network.networks."80-mobile-nixos-usb" = {
        matchConfig = {
          Name = "mobile*";
        };
        address = [ "172.16.42.2/24" ];
        linkConfig = {
          ActivationPolicy = "bound";
        };
      };
    }

    # stateVersion
    { system.stateVersion = "24.11"; }
  ];
}
