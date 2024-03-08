{...}: {
  boot.initrd.systemd = {
    enable = true;
    emergencyAccess = true;
  };
  # enable systemd EFI support in initrd
  boot.initrd.availableKernelModules = ["efivarfs"];
}
