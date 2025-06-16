{
  config,
  suites,
  profiles,
  lib,
  ...
}:
{
  imports =
    suites.mobile
    ++ (with profiles; [
      virtualization.waydroid
      hardware.backlight
      users.yinfeng
    ])
    ++ [
      ./_hardware.nix
    ];

  config = lib.mkMerge [
    {
      hardware.enableRedistributableFirmware = true;

      services.desktopManager.gnome.enable = true;
      services.power-profiles-daemon.enable = false;
      services.tlp = {
        enable = true;
        settings = {
          CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
          CPU_ENERGY_PERF_POLICY_ON_AC = "balance_power";
        };
      };

      networking.campus-network = {
        enable = true;
        auto-login.enable = true;
      };
      home-manager.users.yinfeng =
        { suites, ... }:
        {
          imports = suites.mobile;
        };

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
      };
      kukui.disko = {
        # device = "/dev/mmcblk0";
        device = "/dev/sda";
        partitions = {
          root = {
            priority = 3;
            size = "100%";
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
                    swap.swapfile.size = "8G";
                  };
                };
            };
          };
        };
      };
      fileSystems."/persist".neededForBoot = true;
      fileSystems."/var/log".neededForBoot = true;
      services.zswap.enable = true;

      system.nproc = 8;
    }

    # stateVersion
    { system.stateVersion = "25.05"; }
  ];
}
