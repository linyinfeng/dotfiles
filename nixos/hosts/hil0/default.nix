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
      services.matrix
      services.matrix-sliding-sync
      services.matrix-chatgpt-bot
      services.mastodon
      services.maddy
      services.well-known
      services.hydra
      nix.hydra-builder-server
      nix.hydra-builder-client
      nix.access-tokens
    ])
    ++ [
      "${modulesPath}/profiles/qemu-guest.nix"
    ];

  config = lib.mkMerge [
    {
      boot.loader = {
        # efi support of hetzner is in beta
        # no efi variables to touch
        efi.canTouchEfiVariables = false;
        grub = {
          enable = true;
          efiSupport = true;
          device = "/dev/sda";
        };
      };
      boot.initrd.availableKernelModules = ["ahci" "xhci_pci" "virtio_pci" "sd_mod" "sr_mod"];

      boot.tmp.cleanOnBoot = true;
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
      fileSystems."/tmp" = btrfsSubvolMain "@tmp" {};
      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/5C56-7693";
        fsType = "vfat";
        options = ["dmask=077" "fmask=177"];
      };
      services.zswap.enable = true;
      swapDevices = [
        {
          device = "/swap/swapfile";
        }
      ];
    }

    # networking
    (lib.mkIf (!config.system.is-vm) {
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

    # hydra extra configurations
    {
      services.hydra.buildMachinesFiles = [
        "/etc/nix-build-machines/hydra-builder/machines"
      ];
      # limit cpu usage of nix eval and builds
      systemd.services.nix-daemon.serviceConfig.CPUWeight = "idle";
      systemd.services.hydra-evaluator.serviceConfig.CPUWeight = "idle";
    }

    # mastodon extra configurations
    {
      services.mastodon.streamingProcesses = 3; # number of cpu cores - 1
    }

    # stateVersion
    {
      system.stateVersion = "23.11";
    }
  ];
}
