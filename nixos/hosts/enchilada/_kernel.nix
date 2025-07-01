{
  config,
  profiles,
  lib,
  ...
}:

{
  imports = with profiles; [
    boot.kernel.sdm845-mainline
  ];

  # TODO update
  boot.android.bootImg.device = "/dev/null";

  mobile.boot.stage-1.kernel.useNixOSKernel = true;
  mobile.boot.stage-1.kernel.package = lib.mkForce (
    config.boot.kernelPackages.kernel
    // {
      isQcdt = false;
      isExynosDT = false;
    }
  );
  # not used
  # boot.img only support Image.gz
  # system.boot.loader.kernelFile = "vmlinuz.efi";

  boot.initrd = {
    includeDefaultModules = false;
    availableKernelModules = [
      # EMMC
      "mmc_block"
    ];
  };
}
