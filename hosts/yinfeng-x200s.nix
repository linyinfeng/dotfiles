{ suites, ... }:

{
  imports =
    suites.homeServer ++
    suites.gfw;

  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";
  time.timeZone = "Asia/Shanghai";

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/sda";
  };
  boot.initrd.availableKernelModules = [ "uhci_hcd" "ehci_pci" "ahci" "usb_storage" "sd_mod" ];

  hardware.enableRedistributableFirmware = true;

  networking = {
    useDHCP = false;
    interfaces.enp0s25.useDHCP = true;
    # wireless.enable = true;
    # interfaces.wls1.useDHCP = true;
  };

  nix.binaryCaches = [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" ];

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/25f4278d-36a3-46db-90cf-6f9e3755e2ef";
      fsType = "btrfs";
    };
  swapDevices =
    [{ device = "/dev/disk/by-uuid/7e9bf784-aaf3-42c3-a9f3-f28b091a3b52"; }];
}
