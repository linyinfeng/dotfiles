{
  config,
  suites,
  profiles,
  lib,
  ...
}:
let
  inherit (config.networking) hostName;
in
{
  imports =
    suites.mobileWorkstation
    ++ suites.games
    ++ (with profiles; [
      boot.secure-boot
      boot.lanzaboote-uki
      security.tpm
      virtualization.waydroid
      services.godns
      services.nginx
      services.acme
      hardware.backlight
      hardware.nvidia-egpu
      users.yinfeng
    ])
    ++ [
      ./_hardware.nix
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

      services.fwupd.enable = true;

      networking.campus-network = {
        enable = true;
        auto-login.enable = true;
      };
      services.godns = {
        ipv6.settings = {
          domains = [
            {
              domain_name = "li7g.com";
              sub_domains = [ hostName ];
            }
          ];
          ip_type = "IPv6";
          ip_urls = [
            "https://myip.biturl.top"
            "https://ipecho.net/plain"
            "https://api-ipv6.ip.sb/ip"
          ];
        };
      };

      home-manager.users.yinfeng =
        { suites, ... }:
        {
          imports = suites.full;
        };

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

      system.nproc = 16;
    }

    # stateVersion
    { system.stateVersion = "24.11"; }
  ];
}
