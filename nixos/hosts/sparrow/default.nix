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
      graphical.gnome
      graphical.niri
      graphical.activate-linux
      services.acme
      services.nginx
      networking.behind-fw
      networking.fw-proxy
      virtualization.waydroid
      hardware.backlight
      hardware.tablet
      nix.hydra-builder-client
      users.yinfeng
    ])
    ++ [
      ./_hardware.nix
    ];

  config = lib.mkMerge [
    {
      services.desktopManager.gnome.enable = true;

      services.tailscale.enable = true;
      networking.campus-network = {
        enable = true;
        auto-login.enable = true;
      };
      systemd.network.wait-online.enable = false; # wifi are managed by nm
      home-manager.users.yinfeng =
        { suites, profiles, ... }:
        {
          imports =
            suites.mobile
            ++ (with profiles; [
              gnome
              niri
              alacritty
            ]);
          programs = {
            niri = {
              default-column-proportion = 1.0; # open everything in full width
            };
            noctalia.extraSettings = {
              dock.enabled = false;
            };
          };
        };
      i18n.inputMethod.type = "fcitx5";

      # faster build
      documentation.man.generateCaches = false;

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
        diskName = "main";
        device = "/dev/mmcblk0";
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
                };
            };
          };
        };
      };
      fileSystems."/persist".neededForBoot = true;
      fileSystems."/var/log".neededForBoot = true;

      zramSwap.enable = true;

      system.nproc = 8;
    }

    # stateVersion
    { system.stateVersion = "25.11"; }
  ];
}
