{
  lib,
  ...
}:
lib.mkMerge [
  {
    boot.loader.grub.enable = true;
    boot.initrd.availableKernelModules = [
      "uhci_hcd"
      "ehci_pci"
      "ahci"
      "sd_mod"
    ];
    boot.kernelModules = [ "kvm-intel" ];
  }
]
