{
  config,
  profiles,
  lib,
  ...
}:

{
  imports = [ profiles.boot.kernel.sdm845-mainline ];

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
  system.boot.loader.kernelFile = "vmlinuz.efi";
}
