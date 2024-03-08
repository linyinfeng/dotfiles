{
  config,
  lib,
  ...
}: {
  options = {
    # TODO wait for https://nixpk.gs/pr-tracker.html?pr=282022
    boot.initrd.systemd.root = lib.mkOption {
      type = lib.types.str;
      default = "fstab";
    };
  };
  config = {
    boot.initrd.systemd = {
      enable = true;
      emergencyAccess = true;
    };

    # TODO wait for https://nixpk.gs/pr-tracker.html?pr=282022
    # enable systemd EFI support in initrd
    boot.initrd.availableKernelModules = ["efivarfs"];
    boot.kernelParams = ["root=${config.boot.initrd.systemd.root}"];
  };
}
