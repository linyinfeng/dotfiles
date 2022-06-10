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

  btrfsSubvolMain = btrfsSubvol "/dev/disk/by-uuid/61c8be1d-7cb6-4a6d-bfa1-1fef8cadbe2d";

  windowsCMountPoint = "/media/windows/c";

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
      services.godns
      virtualization.waydroid
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
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.video.hidpi.enable = true;
  programs.steam.hidpi = {
    enable = true;
    scale = "2";
  };

  services.thermald.enable = true;
  services.power-profiles-daemon.enable = false;
  services.tlp = {
    enable = true;
    settings = {
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };

  services.fwupd.enable = true;

  boot.blacklistedKernelModules = [ "nouveau" ];

  virtualisation.kvmgt = {
    enable = true;
    device = "0000:00:02.0";
    vgpus = {
      i915-GVTg_V5_4 = {
        uuid = [
          "fb70adc6-d612-4af4-bfcd-94939e5ca225"
        ];
      };
    };
  };

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
    # ipv4.settings = {
    #   domains = [{
    #     domain_name = "li7g.com";
    #     sub_domains = [ "t460p" ];
    #   }];
    #   ip_type = "IPv4";
    #   ip_interface = "enp0s31f6";
    # };
    ipv6.settings = {
      domains = [{
        domain_name = "li7g.com";
        sub_domains = [ "t460p" ];
      }];
      ip_type = "IPv6";
      ip_interface = "enp0s31f6";
    };
  };

  # mc-client
  home-manager.users.yinfeng = { config, ... }:
    let
      gameDir = ".local/share/mc-li7g-com";
    in
    {
      home.packages = [
        (pkgs.writeShellScriptBin "mc-li7g-com" ''
          "${pkgs.mc-config.client-launcher}/bin/minecraft" \
            --gameDir "${config.home.homeDirectory}/${gameDir}"
        '')
      ];
      home.global-persistence.directories = [
        gameDir
      ];
    };

  environment.global-persistence.enable = true;
  environment.global-persistence.root = "/persist";

  fonts.fontconfig.localConf = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <dir>${windowsCMountPoint}/Windows/Fonts</dir>
    </fontconfig>
  '';

  boot.initrd.luks.forceLuksSupportInInitrd = true;
  boot.initrd.kernelModules = [ "tpm" "tpm_tis" "tpm_crb" ];
  boot.initrd.preLVMCommands = ''
    waitDevice /dev/disk/by-uuid/65aa660c-5b99-4663-a9cb-c69e18b6b6fd
    ${pkgs.clevis}/bin/clevis luks unlock -d /dev/disk/by-uuid/65aa660c-5b99-4663-a9cb-c69e18b6b6fd -n crypt-root
  '';
  fileSystems."/" =
    {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "defaults" "size=8G" "mode=755" ];
    };
  fileSystems."/persist" = btrfsSubvolMain "@persist" { neededForBoot = true; };
  fileSystems."/var/log" = btrfsSubvolMain "@var-log" { neededForBoot = true; };
  fileSystems."/persist/.snapshots" = btrfsSubvolMain "@snapshots" { };
  fileSystems."/nix" = btrfsSubvolMain "@nix" { neededForBoot = true; };
  fileSystems."/swap" = btrfsSubvolMain "@swap" { };
  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/8F31-70B2";
      fsType = "vfat";
    };
  fileSystems.${windowsCMountPoint} =
    {
      device = "/dev/disk/by-uuid/ECB0C2DCB0C2AD00";
      fsType = "ntfs";
      options = [ "ro" "fmask=333" "dmask=222" ];
    };
  swapDevices =
    [{
      device = "/swap/swapfile";
    }];
}
