{ suites, ... }:

let

  btrfsSubvol = subvol: extraConfig: {
    device = "/dev/disk/by-uuid/61c8be1d-7cb6-4a6d-bfa1-1fef8cadbe2d";
    fsType = "btrfs";
    options = [ "subvol=${subvol}" "compress=zstd" ];
  } // extraConfig;

in
{
  imports =
    suites.mobileWorkstation ++
    suites.game ++
    suites.fw ++
    suites.chia ++
    suites.user-yinfeng;

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

  hardware.enableRedistributableFirmware = true;
  hardware.video.hidpi.enable = true;

  powerManagement.cpuFreqGovernor = "powersave";

  services.portal = {
    host = "portal.li7g.com";
    client.enable = true;
  };

  environment.global-persistence.enable = true;
  environment.global-persistence.root = "/persist";

  fileSystems."/" =
    {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "defaults" "size=8G" "mode=755" ];
    };
  boot.initrd.luks.devices."crypt-root".device =
    "/dev/disk/by-uuid/65aa660c-5b99-4663-a9cb-c69e18b6b6fd";
  fileSystems."/persist" = btrfsSubvol "@persist" { neededForBoot = true; };
  fileSystems."/nix" = btrfsSubvol "@nix" { neededForBoot = true; };
  fileSystems."/swap" = btrfsSubvol "@swap" { };
  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/8F31-70B2";
      fsType = "vfat";
    };
  fileSystems."/windows/c" =
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
