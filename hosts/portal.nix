{ suites, ... }:

{
  imports =
    suites.overseaServer;

  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";
  time.timeZone = "Asia/Shanghai";

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/vda";
  };
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];

  boot.tmpOnTmpfs = true;

  networking = {
    useDHCP = false;
    interfaces.ens3.useDHCP = true;
  };

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/c02e1983-731b-4aab-96dc-73e594901c80";
      fsType = "ext4";
    };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/961406a7-4dac-4d45-80e9-ef9b0d4fab99"; }];
}
