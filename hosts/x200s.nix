{ config, suites, lib, ... }:

{
  imports =
    suites.homeServer ++
    suites.monitoring ++
    suites.auto-upgrade ++
    suites.fw;

  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";
  time.timeZone = "Asia/Shanghai";

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/sda";
  };
  boot.initrd.availableKernelModules = [ "uhci_hcd" "ehci_pci" "ahci" "usb_storage" "sd_mod" ];

  services.fwupd.enable = true;

  services.logind.lidSwitch = "ignore";

  services.godns = {
    ipv4.settings = {
      domains = [{
        domain_name = "li7g.com";
        sub_domains = [ "x200s" ];
      }];
      ip_type = "IPv4";
      ip_url = "https://myip.biturl.top";
    };
    ipv6.settings = {
      domains = [{
        domain_name = "li7g.com";
        sub_domains = [ "x200s" ];
      }];
      ip_type = "IPv6";
      ip_interface = "enp0s25";
    };
  };

  hardware.enableRedistributableFirmware = true;

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/25f4278d-36a3-46db-90cf-6f9e3755e2ef";
      fsType = "btrfs";
    };
  swapDevices =
    [{ device = "/dev/disk/by-uuid/7e9bf784-aaf3-42c3-a9f3-f28b091a3b52"; }];
}
