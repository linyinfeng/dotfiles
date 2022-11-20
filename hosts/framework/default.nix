{ inputs, config, pkgs, suites, profiles, lib, ... }:

let

  btrfsSubvol = device: subvol: extraConfig: lib.mkMerge [
    {
      inherit device;
      fsType = "btrfs";
      options = [ "subvol=${subvol}" "compress=zstd" "x-gvfs-hide" ];
    }
    extraConfig
  ];

  btrfsSubvolMain = btrfsSubvol "/dev/disk/by-uuid/9f227a19-d570-449f-b4cb-0eecc5b2d227";

in
{
  imports =
    suites.mobileWorkstation ++
    suites.games ++
    (with profiles; [
      nix.access-tokens
      nix.nixbuild
      security.tpm
      networking.wireguard-home
      networking.behind-fw
      networking.fw-proxy
      virtualization.waydroid
      services.godns
      services.smartd
      services.acme
      programs.service-mail
      programs.telegram-send
    ]) ++
    (with profiles.users; [
      yinfeng
    ]) ++ [
      inputs.bootspec-secureboot.nixosModules.bootspec-secureboot
      ./hardware.nix
    ];

  config = lib.mkMerge [
    {
      i18n.defaultLocale = "en_US.UTF-8";
      console.keyMap = "us";
      time.timeZone = "Asia/Shanghai";

      # use bootspec-secureboot
      boot.loader.efi.canTouchEfiVariables = true;
      boot.loader.systemd-boot = {
        consoleMode = "auto";
        # every boot entry takes about 40MB for EFI partition with bootspec-secureboot
        configurationLimit = 10;
      };
      boot.loader.secureboot = {
        enable = true;
        signingKeyPath = "/sbkeys/generated/db.key";
        signingCertPath = "/sbkeys/generated/db.crt";
      };

      boot.initrd.systemd.enable = true;
      boot.kernelPackages = pkgs.linuxPackages_latest;
      boot.kernelModules = [ "kvm-intel" ];

      hardware.enableRedistributableFirmware = true;
      # hardware.video.hidpi.enable = true;
      programs.steam.hidpi = {
        enable = true;
        scale = "2";
      };

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
      # TODO see https://github.com/DeterminateSystems/bootspec-secureboot/issues/203
      services.fwupd.enable = true;

      boot.binfmt.emulatedSystems = [
        "aarch64-linux"
      ];

      services.xserver.desktopManager.gnome.enable = true;
      services.fprintd.enable = true;

      security.acme.certs."main" = {
        domain = "*.li7g.com";
        extraDomainNames = [
          "*.zt.li7g.com"
          "*.ts.li7g.com"
        ];
      };
      networking.campus-network = {
        enable = true;
        auto-login.enable = true;
      };
      services.portal = {
        host = "portal.li7g.com";
        client.enable = true;
      };
      services.godns = {
        ipv6.settings = {
          domains = [{
            domain_name = "li7g.com";
            sub_domains = [ "framework" ];
          }];
          ip_type = "IPv6";
          ip_interface = "enp0s13f0u4u4u5";
        };
      };

      environment.global-persistence.enable = true;
      environment.global-persistence.root = "/persist";

      services.btrfs.autoScrub = {
        enable = true;
        fileSystems = [
          "/dev/disk/by-uuid/9f227a19-d570-449f-b4cb-0eecc5b2d227"
        ];
      };

      boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
      boot.initrd.luks.devices = {
        crypt-root = {
          device = "/dev/disk/by-uuid/46fad3b7-6287-4bc2-a45e-0cdd053cbb85";
          allowDiscards = true;
        };
      };
      fileSystems."/" =
        {
          device = "tmpfs";
          fsType = "tmpfs";
          options = [ "defaults" "size=8G" "mode=755" ];
        };
      fileSystems."/persist" = btrfsSubvolMain "@persist" { neededForBoot = true; };
      fileSystems."/var/log" = btrfsSubvolMain "@var-log" { neededForBoot = true; };
      fileSystems."/nix" = btrfsSubvolMain "@nix" { neededForBoot = true; };
      fileSystems."/swap" = btrfsSubvolMain "@swap" { };
      fileSystems."/sbkeys" = btrfsSubvolMain "@sbkeys" { };
      fileSystems."/boot" =
        {
          device = "/dev/disk/by-uuid/5C56-7693";
          fsType = "vfat";
        };
      swapDevices =
        [{
          device = "/swap/swapfile";
        }];
    }

    # windows fonts
    (
      let
        windowsPart = "/dev/disk/by-uuid/A082C3A482C37CF2";
        windowsMountPoint = "/media/windows";
      in
      {
        users.groups.windows = {
          gid = config.ids.gids.windows;
        };
        fileSystems.${windowsMountPoint} =
          {
            device = windowsPart;
            fsType = "ntfs3";
            options = [ "gid=${toString config.users.groups.windows.gid}" "ro" "fmask=337" "dmask=227" ];
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
  ];
}
