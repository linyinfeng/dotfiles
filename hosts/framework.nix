{ config, pkgs, suites, profiles, lib, ... }:

let

  btrfsSubvol = device: subvol: extraConfig: lib.mkMerge [
    {
      inherit device;
      fsType = "btrfs";
      options = [ "subvol=${subvol}" "compress=zstd" ];
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
      programs.service-mail
      programs.telegram-send
    ]) ++
    (with profiles.users; [
      yinfeng
    ]);

  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";
  time.timeZone = "Asia/Shanghai";

  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot = {
      enable = true;
      consoleMode = "auto";
    };
  };
  boot.kernelPackages = pkgs.linuxPackages_xanmod;
  boot.kernelModules = [ "kvm-intel" ];

  hardware.enableRedistributableFirmware = true;
  hardware.video.hidpi.enable = true;
  programs.steam.hidpi = {
    enable = true;
    scale = "2";
  };

  services.thermald.enable = true;
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = true;
  services.fwupd.enable = true;

  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
  ];

  services.xserver.desktopManager.gnome.enable = true;

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
      ip_interface = "enp0s13f0u4u1";
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

  boot.initrd.luks.forceLuksSupportInInitrd = true;
  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ "tpm" "tpm_tis" "tpm_crb" ];
  boot.initrd.preLVMCommands = ''
    waitDevice /dev/disk/by-uuid/9f227a19-d570-449f-b4cb-0eecc5b2d227
    ${pkgs.clevis}/bin/clevis luks unlock -d /dev/disk/by-uuid/9f227a19-d570-449f-b4cb-0eecc5b2d227 -n crypt-root
  '';
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
