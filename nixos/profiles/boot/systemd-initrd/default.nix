{
  config,
  lib,
  ...
}: {
  options = {
    boot.initrd.systemd.gpt-auto.enable = lib.mkEnableOption "gpt-auto";
  };
  config = {
    boot.initrd.systemd = {
      enable = true;
      emergencyAccess = true;
    };
    # enable systemd EFI support in initrd
    boot.initrd.availableKernelModules = ["efivarfs"];
    boot.kernelParams = lib.mkIf (!config.boot.initrd.systemd.gpt-auto.enable) ["rd.systemd.gpt_auto=0"];
  };
}
