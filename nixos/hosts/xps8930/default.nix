{
  config,
  pkgs,
  lib,
  suites,
  profiles,
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

  btrfsSubvolMain = btrfsSubvol "/dev/disk/by-uuid/3d22521e-0f64-4a64-ad29-40dcabda13a2";
  btrfsSubvolData = btrfsSubvol "/dev/disk/by-uuid/fc047db2-0ba9-445a-9b84-194af545fa23";
in {
  imports =
    suites.workstation
    ++ (with profiles; [
      nix.access-tokens
      nix.nixbuild
      security.tpm
      networking.wireguard-home
      networking.behind-fw
      networking.fw-proxy
      services.godns
      services.smartd
      services.nginx
      services.acme
      services.ssh-honeypot
      services.flatpak
      programs.service-mail
      programs.tg-send
      users.yinfeng
    ]);

  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot = {
      enable = true;
      consoleMode = "max";
    };
  };
  hardware.enableRedistributableFirmware = true;
  services.fwupd.enable = true;

  services.xserver.desktopManager.gnome.enable = true;

  virtualisation.kvmgt = {
    enable = true;
    device = "0000:00:02.0";
    vgpus = {
      i915-GVTg_V5_4 = {
        uuid = [
          "15feffce-745b-4cb6-9f48-075af14cdb6f"
        ];
      };
    };
  };
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
  ];

  networking.campus-network = {
    enable = true;
    auto-login.enable = true;
  };
  services.portal = {
    host = "portal.li7g.com";
    client.enable = true;
  };
  services.godns = {
    ipv4.settings = {
      domains = [
        {
          domain_name = "li7g.com";
          sub_domains = ["xps8930"];
        }
      ];
      ip_type = "IPv4";
      ip_interface = "enp4s0";
    };
    ipv6.settings = {
      domains = [
        {
          domain_name = "li7g.com";
          sub_domains = ["xps8930"];
        }
      ];
      ip_type = "IPv6";
      ip_interface = "enp4s0";
    };
  };

  home-manager.users.yinfeng = {suites, ...}: {imports = suites.full;};

  boot.tmp.useTmpfs = true;
  services.fstrim.enable = true;
  environment.global-persistence.enable = true;
  environment.global-persistence.root = "/persist";
  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [
      "/dev/disk/by-uuid/3d22521e-0f64-4a64-ad29-40dcabda13a2"
      "/dev/disk/by-uuid/fc047db2-0ba9-445a-9b84-194af545fa23"
    ];
  };

  boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usbhid" "uas" "sd_mod" "sr_mod"];
  boot.initrd.luks.forceLuksSupportInInitrd = true;
  boot.initrd.kernelModules = ["tpm" "tpm_tis" "tpm_crb"];
  boot.initrd.preLVMCommands = ''
    waitDevice /dev/disk/by-uuid/29bb6dbb-7348-42a0-a9e9-6e7daa89d32e
    ${pkgs.clevis}/bin/clevis luks unlock -d /dev/disk/by-uuid/29bb6dbb-7348-42a0-a9e9-6e7daa89d32e -n crypt-root
    waitDevice /dev/disk/by-uuid/0f9a546e-f458-46d9-88a4-4f6b157579ea
    ${pkgs.clevis}/bin/clevis luks unlock -d /dev/disk/by-uuid/0f9a546e-f458-46d9-88a4-4f6b157579ea -n crypt-data
  '';
  fileSystems."/" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = ["defaults" "size=16G" "mode=755"];
  };
  fileSystems."/nix" = btrfsSubvolMain "@nix" {neededForBoot = true;};
  fileSystems."/persist" = btrfsSubvolData "@persist" {neededForBoot = true;};
  fileSystems."/var/log" = btrfsSubvolMain "@var-log" {neededForBoot = true;};
  fileSystems."/swap" = btrfsSubvolMain "@swap" {};
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/74C9-BFBC";
    fsType = "vfat";
  };
  fileSystems."/media/data" = btrfsSubvolData "@data" {};
  swapDevices = [
    {
      device = "/swap/swapfile";
    }
  ];
}
